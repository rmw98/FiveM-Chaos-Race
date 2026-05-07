// --- File: MainViewModel.cs (YOUR CODE, BUT CORRECTED) ---

using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Input;

namespace ChaosConfigEditor
{
    public class EffectGroup : INotifyPropertyChanged
    {
        public string GroupName { get; set; } = "Unknown";
        public ObservableCollection<Effect> Effects { get; set; } = new ObservableCollection<Effect>();
        public event PropertyChangedEventHandler? PropertyChanged;
        protected void OnPropertyChanged(string propertyName) => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }

    public class MainViewModel : INotifyPropertyChanged
    {
        private string _configFilePath = "";
        private string _fileHeader = "";
        private string _fileFooter = "";
        private FileSystemWatcher? _watcher;
        private readonly Stack<(EffectGroup Group, Effect DeletedEffect)> _deletedEffectsStack = new();

        public ObservableCollection<EffectGroup> EffectGroups { get; set; } = new ObservableCollection<EffectGroup>();

        public ICommand AddEffectCommand { get; private set; }
        public ICommand SaveCommand { get; private set; }
        public ICommand ToggleAllCommand { get; private set; }
        public ICommand DisableGroupCommand { get; private set; }
        public ICommand EnableGroupCommand { get; private set; }
        public ICommand ToggleEffectCommand { get; private set; }
        public ICommand DeleteEffectCommand { get; private set; }
        public ICommand UndoDeleteCommand { get; private set; }


        public MainViewModel()
        {
            AddEffectCommand = new RelayCommand(p => AddEffect());
            SaveCommand = new RelayCommand(p => SaveFile());
            ToggleAllCommand = new RelayCommand(ToggleAll);
            DisableGroupCommand = new RelayCommand(p => ToggleGroup(p, true));
            EnableGroupCommand = new RelayCommand(p => ToggleGroup(p, false));
            ToggleEffectCommand = new RelayCommand(ToggleEffect);
            DeleteEffectCommand = new RelayCommand(DeleteEffect);
            UndoDeleteCommand = new RelayCommand(p => UndoDelete(), p => _deletedEffectsStack.Count > 0);
        }

        private void SortEffectsInGroup(EffectGroup group)
        {
            var sortedEffects = group.Effects.OrderBy(e => e.Name).ToList();

            for (int i = 0; i < sortedEffects.Count; i++)
            {
                int oldIndex = group.Effects.IndexOf(sortedEffects[i]);
                if (oldIndex != i)
                {
                    group.Effects.Move(oldIndex, i);
                }
            }
        }

        public void Initialize()
        {
            string? exePath = AppContext.BaseDirectory;
            if (exePath == null)
            {
                MessageBox.Show("Could not determine application path.", "Fatal Error", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }
            _configFilePath = Path.Combine(exePath, "config.lua");
            LoadFile();
            SetupFileWatcher();
        }

        private void SetupFileWatcher()
        {
            string? directory = Path.GetDirectoryName(_configFilePath);
            if (string.IsNullOrEmpty(directory) || !Directory.Exists(directory)) return;

            _watcher = new FileSystemWatcher(directory)
            {
                Filter = Path.GetFileName(_configFilePath),
                NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.FileName,
                EnableRaisingEvents = true
            };
            _watcher.Changed += OnConfigFileChanged;
        }

        private void OnConfigFileChanged(object? sender, FileSystemEventArgs e)
        {
            Application.Current?.Dispatcher.Invoke(() =>
            {
                if (_watcher != null) _watcher.EnableRaisingEvents = false;
                if (MessageBox.Show("config.lua was changed externally. Reload the file?", "File Changed", MessageBoxButton.YesNo, MessageBoxImage.Information) == MessageBoxResult.Yes)
                {
                    LoadFile();
                }
                if (_watcher != null) _watcher.EnableRaisingEvents = true;
            });
        }

        private void LoadFile()
        {
            _deletedEffectsStack.Clear();

            if (!File.Exists(_configFilePath))
            {
                MessageBox.Show($"Could not find config.lua at:\n{_configFilePath}\n\nPlease place the editor .exe in the same folder.", "File Not Found", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }
            try
            {
                string luaString = File.ReadAllText(_configFilePath);
                ParseLuaConfig(luaString);
                OnPropertyChanged(nameof(EffectGroups));
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Critical error loading config file: {ex.Message}\n\n{ex.StackTrace}", "Load Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void ParseLuaConfig(string luaString)
        {
            var effectsTableRegex = new Regex(@"Config\.Effects\s*=\s*\{([\s\S]*)\}", RegexOptions.Compiled);
            var match = effectsTableRegex.Match(luaString);
            if (!match.Success) throw new Exception("Could not find 'Config.Effects = { ... }' table.");

            var tableContent = match.Groups[1].Value;
            _fileHeader = luaString.Substring(0, match.Index);
            _fileFooter = luaString.Substring(match.Index + match.Length);

            var loadedGroups = new Dictionary<string, EffectGroup>();
            var currentContextKey = "unknown";
            var errorLines = new List<string>();

            var lines = tableContent.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None);

            for (int i = 0; i < lines.Length; i++)
            {
                var line = lines[i];
                var trimmedLine = line.Trim();
                if (string.IsNullOrWhiteSpace(trimmedLine)) continue;

                var contextMatch = Regex.Match(trimmedLine, @"--\s*'(.*?)' context");
                if (contextMatch.Success) { currentContextKey = contextMatch.Groups[1].Value; continue; }

                var multiContextMatch = Regex.Match(trimmedLine, @"--\s*(Multi-context) effects");
                if (multiContextMatch.Success) { currentContextKey = "Multi-context"; continue; }

                // *** FIX IS HERE: This logic now correctly finds effect lines, even with spaces after the comment. ***
                var isDisabled = trimmedLine.StartsWith("--");
                var effectBlock = trimmedLine;
                if (isDisabled)
                {
                    // Remove the "--" and trim again to get to the "{"
                    effectBlock = trimmedLine.Substring(2).Trim();
                }

                if (effectBlock.StartsWith("{"))
                {
                    try
                    {
                        string? SafeGetValue(string pattern) { var m = Regex.Match(effectBlock, pattern); return m.Success ? m.Groups[1].Value : null; }
                        ;

                        var effect = new Effect
                        {
                            Name = SafeGetValue(@"name\s*=\s*""([^""]+)""") ?? "Unnamed Effect",
                            ClientEvent = SafeGetValue(@"clientEvent\s*=\s*""([^""]+)""") ?? "chaos:unknown",
                            Weight = int.TryParse(SafeGetValue(@"weight\s*=\s*(\d+)"), out int w) ? w : 1,
                            Cost = SafeGetValue(@"cost\s*=\s*(\d+)"),
                            Type = SafeGetValue(@"type\s*=\s*'([^']+)'") ?? "bad",
                            Duration = int.TryParse(SafeGetValue(@"duration\s*=\s*(\d+)"), out int d) ? d : 0,
                            IsDisabled = isDisabled
                        };

                        var contextStr = SafeGetValue(@"context\s*=\s*\{([^}]+)\}");
                        if (!string.IsNullOrEmpty(contextStr))
                        {
                            var contexts = contextStr.Replace("'", "").Replace("\"", "").Split(',');
                            foreach (var ctx in contexts) { if (!string.IsNullOrWhiteSpace(ctx)) effect.Contexts.Add(ctx.Trim()); }
                        }

                        if (!loadedGroups.ContainsKey(currentContextKey))
                        {
                            loadedGroups[currentContextKey] = new EffectGroup { GroupName = currentContextKey };
                        }
                        loadedGroups[currentContextKey].Effects.Add(effect);
                    }
                    catch (Exception ex)
                    {
                        errorLines.Add($"Line {i + 1}: {trimmedLine.Substring(0, Math.Min(trimmedLine.Length, 50))}... \nError: {ex.Message}\n");
                    }
                }
            }

            var order = new[] { "any", "car", "foot", "plane", "boat", "multi-context", "unknown" };
            var orderedGroups = loadedGroups.Values.OrderBy(g => Array.IndexOf(order, g.GroupName.ToLower())).ToList();

            EffectGroups.Clear();
            foreach (var group in orderedGroups)
            {
                group.GroupName = char.ToUpper(group.GroupName[0]) + group.GroupName.Substring(1);
                SortEffectsInGroup(group);
                EffectGroups.Add(group);
            }

            if (errorLines.Any())
            {
                MessageBox.Show("Some effects could not be loaded due to formatting errors:\n\n" + string.Join("\n", errorLines), "Parsing Errors", MessageBoxButton.OK, MessageBoxImage.Warning);
            }
        }

        private void SaveFile()
        {
            if (_watcher != null) _watcher.EnableRaisingEvents = false;
            try
            {
                var sb = new StringBuilder();
                sb.Append(_fileHeader);
                sb.AppendLine("Config.Effects = {");

                foreach (var group in EffectGroups)
                {
                    if (!group.Effects.Any())
                    {
                        continue;
                    }

                    string groupKey = group.GroupName.ToLower();
                    if (groupKey == "multi-context") sb.AppendLine($"\n    -- Multi-context effects");
                    else if (groupKey != "unknown") sb.AppendLine($"\n    -- '{groupKey}' context");
                    else sb.AppendLine($"\n    -- UNKNOWN/NEW CONTEXT (Please categorize)");

                    foreach (var effect in group.Effects)
                    {
                        var contextStr = $"{{{string.Join(", ", effect.Contexts.Select(c => $"'{c}'"))}}}";
                        var costStr = string.IsNullOrWhiteSpace(effect.Cost) ? "" : $", cost = {effect.Cost}";

                        // *** FIX: Changed the comment style to be consistent with the input file format. ***
                        var line = $"{{name = \"{effect.Name}\", clientEvent = \"{effect.ClientEvent}\", duration = {effect.Duration},      type = '{effect.Type}', context = {contextStr},    weight = {effect.Weight}{costStr}}},";

                        if (effect.IsDisabled)
                        {
                            sb.AppendLine($"--    {line}"); // Add spaces for consistent formatting
                        }
                        else
                        {
                            sb.AppendLine($"    {line}"); // Add spaces for consistent formatting
                        }
                    }
                }
                sb.Append("}");
                sb.Append(_fileFooter);
                File.WriteAllText(_configFilePath, sb.ToString());

                _deletedEffectsStack.Clear();

                MessageBox.Show("config.lua has been saved successfully!", "Success", MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error saving file: {ex.Message}", "Save Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
            finally
            {
                if (_watcher != null) _watcher.EnableRaisingEvents = true;
            }
        }

        private void AddEffect()
        {
            var newEffect = new Effect { Name = "_New Effect", ClientEvent = "chaos:newEvent", Duration = 10000, Type = "bad", Weight = 1, Cost = "" };
            newEffect.Contexts.Add("any");

            EffectGroup? targetGroup = EffectGroups.FirstOrDefault(g => g.GroupName.ToLower() == "any");
            if (targetGroup != null)
            {
                targetGroup.Effects.Add(newEffect);
            }
            else
            {
                targetGroup = new EffectGroup { GroupName = "Any" };
                targetGroup.Effects.Add(newEffect);
                EffectGroups.Insert(0, targetGroup);
            }

            SortEffectsInGroup(targetGroup);
        }

        private void ToggleAll(object? parameter)
        {
            bool disable = parameter?.ToString() == "disable";
            foreach (var effect in EffectGroups.SelectMany(g => g.Effects)) effect.IsDisabled = disable;
        }

        private void ToggleGroup(object? parameter, bool disable)
        {
            if (parameter is EffectGroup group)
            {
                foreach (var effect in group.Effects)
                {
                    effect.IsDisabled = disable;
                }
            }
        }

        private void ToggleEffect(object? parameter)
        {
            if (parameter is Effect effect) effect.IsDisabled = !effect.IsDisabled;
        }

        private void DeleteEffect(object? parameter)
        {
            if (parameter is not Effect effect) return;

            if (MessageBox.Show($"Are you sure you want to delete '{effect.Name}'?", "Confirm Delete", MessageBoxButton.YesNo, MessageBoxImage.Warning) != MessageBoxResult.Yes)
                return;

            var ownerGroup = EffectGroups.FirstOrDefault(g => g.Effects.Contains(effect));
            if (ownerGroup != null)
            {
                _deletedEffectsStack.Push((ownerGroup, effect));
                ownerGroup.Effects.Remove(effect);
            }
        }

        private void UndoDelete()
        {
            if (_deletedEffectsStack.Count > 0)
            {
                var (group, effectToRestore) = _deletedEffectsStack.Pop();
                group.Effects.Add(effectToRestore);

                SortEffectsInGroup(group);
            }
        }

        public event PropertyChangedEventHandler? PropertyChanged;
        protected void OnPropertyChanged(string propertyName) => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }
}