// TEMPLATE Reusable control pattern

// Properties
// - InputText
// - ButtonLabel
// - OutputText

Set(varInputText, "");
Set(varOutputText, "");

TextInput1.Default = varInputText;
TextInput1.Placeholder = "Type something";

Button1.Text = "Run";
Button1.OnSelect =
    Set(
        varOutputText,
        "Result: " & TextInput1.Text
    );

Label1.Text = varOutputText;
