// File: MainWindow.xaml.cs
using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace ChaosConfigEditor
{
    public class BoolToButtonTextConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return value is bool b && b ? "Enable" : "Disable";
        }
        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) => throw new NotImplementedException();
    }

    public class BoolToButtonStyleConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            string styleKey = value is bool b && b ? "SuccessButton" : "WarningButton";
            return Application.Current.FindResource(styleKey);
        }
        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) => throw new NotImplementedException();
    }

    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            this.DataContext = new MainViewModel();
            this.Loaded += (s, e) => { (this.DataContext as MainViewModel)?.Initialize(); };
        }
    }
}