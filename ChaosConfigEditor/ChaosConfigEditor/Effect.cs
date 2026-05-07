// --- File: Effect.cs (FINAL, WITH UI HELPER PROPERTIES) ---

using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;

namespace ChaosConfigEditor
{
    public class Effect : INotifyPropertyChanged
    {
        private bool _isDisabled;

        public string Name { get; set; } = "Unnamed Effect";
        public string ClientEvent { get; set; } = "chaos:unknown";
        public int Weight { get; set; }
        public string? Cost { get; set; }
        public string Type { get; set; } = "bad";
        public int Duration { get; set; }
        public List<string> Contexts { get; set; } = new List<string>();

        public bool IsDisabled
        {
            get => _isDisabled;
            set
            {
                if (_isDisabled != value)
                {
                    _isDisabled = value;
                    OnPropertyChanged(nameof(IsDisabled));
                }
            }
        }

        // *** FIX: UI HELPER PROPERTIES FOR CONTEXT CHECKBOXES ***
        // These properties connect the UI checkboxes to the 'Contexts' list.
        // The XAML will bind to these instead of the list directly.

        public bool IsAnyContext
        {
            get => Contexts.Contains("any");
            set => SetContext("any", value);
        }

        public bool IsCarContext
        {
            get => Contexts.Contains("car");
            set => SetContext("car", value);
        }

        public bool IsFootContext
        {
            get => Contexts.Contains("foot");
            set => SetContext("foot", value);
        }

        public bool IsPlaneContext
        {
            get => Contexts.Contains("plane");
            set => SetContext("plane", value);
        }

        public bool IsBoatContext
        {
            get => Contexts.Contains("boat");
            set => SetContext("boat", value);
        }

        // Helper method to keep the code clean (DRY - Don't Repeat Yourself)
        private void SetContext(string context, bool shouldHave)
        {
            // If the checkbox is checked, add the context to the list (if it's not already there)
            if (shouldHave)
            {
                if (!Contexts.Contains(context))
                {
                    Contexts.Add(context);
                }
            }
            // If the checkbox is unchecked, remove the context from the list
            else
            {
                Contexts.Remove(context);
            }
            // Notify the UI that the corresponding property has changed.
            OnPropertyChanged($"Is{context.First().ToString().ToUpper() + context.Substring(1)}Context");
        }


        public event PropertyChangedEventHandler? PropertyChanged;
        protected void OnPropertyChanged(string propertyName)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}