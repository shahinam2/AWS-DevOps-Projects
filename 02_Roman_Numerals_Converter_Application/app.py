from flask import Flask, render_template, request

app = Flask(__name__)

def int_to_roman(num):
    """
    Convert an integer to a Roman numeral.
    :param num: Integer to convert (1 <= num <= 3999)
    :return: Roman numeral as a string
    """
    if not (1 <= num <= 3999):
        raise ValueError("Number must be between 1 and 3999")

    roman_numerals = {
        1000: 'M', 900: 'CM', 500: 'D', 400: 'CD',
        100: 'C', 90: 'XC', 50: 'L', 40: 'XL',
        10: 'X', 9: 'IX', 5: 'V', 4: 'IV', 1: 'I'
    }

    result = ""
    for value, numeral in roman_numerals.items():
        while num >= value:
            result += numeral
            num -= value
    return result

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        user_input = request.form.get('number')
        # Check if the input is a digit
        if not user_input.isdigit():
            return render_template('index.html', not_valid=True, error="Not Valid! Please enter a number between 1 and 3999, inclusively.")

        number = int(user_input)
        # Check if the number is within the valid range
        if number < 1 or number > 3999:
            return render_template('index.html', not_valid=True, error="Not Valid! Please enter a number between 1 and 3999, inclusively.")
        
        roman_numeral = int_to_roman(number)
        # Return the result to the result.html template
        return render_template('result.html', number=number, result=roman_numeral)
    return render_template('index.html')

if __name__ == '__main__':
    # app.run(debug=True)
    app.run(debug=True)
