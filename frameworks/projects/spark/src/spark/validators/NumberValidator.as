////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2010 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package spark.validators
{

import flash.globalization.NumberFormatter;
import flash.globalization.NumberParseResult;

import mx.core.mx_internal;
import mx.formatters.IFormatter;
import mx.managers.ISystemManager;
import mx.managers.SystemManager;
import mx.validators.NumberValidatorDomainType;
import mx.validators.ValidationResult;

import spark.globalization.LastOperationStatus;
import spark.validators.supportClasses.NumberValidatorBase;
import spark.validators.supportClasses.GlobalizationUtils;
import spark.formatters.NumberFormatter;
use namespace mx_internal;

[ResourceBundle("validators")]

/**
 *  The NumberValidator class ensures that a String represents a valid number
 *  according to the conventions of a locale.  It can validate <code>int</code>,
 *  <code>uint</code>, and <code>Number</code> objects.
 *
 *  <p>It can ensure that the input falls within a given range
 *  (specified by <code>minValue</code> and <code>maxValue</code>  properties),
 *  is an integer (specified by <code>domain</code>  property),
 *  is non-negative (specified by <code>allowNegative</code>  property),
 *  has the grouping of digits correct per the locale conventions,
 *  has the correct way of specifying negative numbers,
 *  and does not exceed the specified <code>fractionalDigits</code>. The
 *  validator sets default property values from the operating system supplied
 *  locale data but they can be customized for specific needs.</p>
 *
 *  <p>This class internally uses the <code>flash.globalization.NumberFormatter
 *  </code> to obtain locale-specific information.
 *  The NumberValidator class can be used in MXML declarations or in
 *  ActionScript code. This class uses the locale style for specifying the
 *  requested Locale ID, and has methods and properties that are bindable.
 *  </p>
 *  <p>
 *  The flash.globalization.NumberFormatter class uses the underlying
 *  operating system for acquiring locale-specific data and parsing
 *  functionality. In case the operating system does not provide number
 *  formatting, this class provides fallback functionality.
 *  </p>
 *
 *  @mxml
 *
 *  <p>The <code>&lt;spark:NumberValidator&gt;</code> tag
 *  inherits all of the tag attributes of its superclass,
 *  and adds the following tag attributes:</p>
 *
 *  <pre>
 *  &lt;spark:NumberValidator
 *    allowNegative="true|false"
 *    decimalPointCountError="The decimal separator can only occur once."
 *    decimalSeparator="(locale specified string or customized by user)."
 *    domain="real|int"
 *    exceedsMaxError="The number entered is too large."
 *    integerError="The number must be an integer."
 *    invalidCharError="The input contains invalid characters."
 *    invalidFormatCharsError="One of the formatting parameters is invalid."
 *    lowerThanMinError="The amount entered is too small."
 *    maxValue="NaN"
 *    minValue="NaN"
 *    negativeError="The amount may not be negative."
 *    negativeNumberFormatError="The negative format of the input number is
 *    incorrect."
 *    negativeSymbol="(locale specified read-only string)."
 *    negativeSymbolError="The negative symbol is repeated or not in right
 *    place."
 *    parseError="The input string could not be parsed."
 *    fractionalDigits="(locale specified number or customized by user)."
 *    fractionalDigitsError="The amount entered has too many digits beyond the
 *    decimal point."
 *    groupingPattern="(locale specified string or customized by user)."
 *    groupingSeparator="(locale specified string or customized by user)."
 *    groupingSeparationError="The number digits grouping is not following the
 *    grouping pattern."
 *  /&gt;
 *  </pre>
 *
 *  @includeExample examples/NumberValidatorExample.mxml
 *
 *  @see flash.globalization.NumberFormatter
 *
 *  @langversion 3.0
 *  @playerversion Flash 10.1
 *  @playerversion AIR 2.5
 *  @productversion Flex 4.5
 */
public class NumberValidator extends NumberValidatorBase
{
    include "../core/Version.as";

    //--------------------------------------------------------------------------
    //
    //  Class Constants
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    private static const NEGATIVE_NUMBER_FORMAT:String = "negativeNumberFormat";

    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructs a new NumberValidator object to validate numbers according
     *  to the conventions of a given locale.
     *  <p>
     *  The locale for this class is supplied by the locale style.
     *  The locale style can be set in several ways:
     *  </p>
     *  <ul>
     *  <li>         *
     *  Inheriting the style from a UIComponent by calling the UIComponent's
     *  addStyleClient method.
     *  </li>
     *  <li>
     *  By using the class in an MXML declaration and inheriting the
     *  locale from the document that contains the declaration.
     *  <listing version="3.0" >
     *  &lt;fx:Declarations&gt;
     *         &lt;s:NumberValidator id="nv" /&gt;
     *  &lt;/fx:Declarations&gt;
     *  </listing>
     *  </li>
     *  <li>
     *  By using an MXML declaration and specifying the locale value in
     *  the list of assignments.
     *  <listing version="3.0" >
     *  &lt;fx:Declarations&gt;
     *      &lt;s:NumberValidator id="nv_French_France" locale="fr_FR" /&gt;
     *  &lt;/fx:Declarations&gt;
     *  </listing>
     *  </li>
     *  <li>
     *  Calling the setStyle method, e.g.
     *  <code>nv.setStyle("locale", "fr-FR")</code>
     *  </li>
     *  </ul>
     *  <p>
     *  If the locale style is not set by one of the above techniques,
     *  the methods of this class that depend on the locale
     *  will throw an error.
     *  </p>         *
     *
     *  @langversion 3.0
     *  @playerversion Flash 10.1
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function NumberValidator()
    {
        super();
    }

    //--------------------------------------------------------------------------
    //
    //  Overridden Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    //  actualLocaleIDName
    //----------------------------------
    
    [Bindable("change")]
    
    /**
     *
     *  @private
     */
    override public function get actualLocaleIDName():String
    {
        return getActualLocaleIDName(NUMBER_VALIDATOR_TYPE);
    }

    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    // negativeNumberFormat
    //----------------------------------

    [Bindable("change")]

    /**
     *  A numeric value that indicates a validating pattern for negative
     *  numbers.
     *  This pattern defines the location of the negative symbol
     *  or parentheses in relation to the numeric portion of the
     *  number to be validated.
     *
     *  <p>The following table summarizes the possible formats for
     *  negative numbers. When a negative number is validated,
     *  the minus sign represents the value of
     *  the <code>negativeSymbol</code> property and the 'n' character
     *  represents numeric value.</p>
     *
     *    <table class="innertable" border="0">
     *        <tr>
     *            <td>Negative number format type</td>
     *            <td>Format</td>
     *        </tr>
     *        <tr>
     *            <td>0</td>
     *            <td>(n)</td>
     *        </tr>
     *        <tr>
     *            <td>1</td>
     *            <td>-n</td>
     *        </tr>
     *        <tr>
     *            <td>2</td>
     *            <td>- n</td>
     *        </tr>
     *        <tr>
     *            <td>3</td>
     *            <td>n-</td>
     *        </tr>
     *        <tr>
     *            <td>4</td>
     *            <td>n -</td>
     *        </tr>
     *    </table>
     *
     *
     *  @default dependent on the locale and operating system.
     *
     *  @throws ArgumentError if the assigned value is not a number
     *  between 0 and 4.
     *
     *  @see #negativeSymbol
     *  @see #format()
     *
     *  @langversion 3.0
     *  @playerversion Flash 10.1
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function get negativeNumberFormat():uint
    {
        return getBasicProperty(properties, NEGATIVE_NUMBER_FORMAT);
    }

    public function set negativeNumberFormat(value:uint):void
    {
        if (!g11nWorkingInstance)
        {
            if (4 < value)
                throw new TypeError();
        }
        setBasicProperty(properties, NEGATIVE_NUMBER_FORMAT, value);
    }

    //--------------------------------------------------------------------------
    //
    //  Properties: Errors
    //
    //--------------------------------------------------------------------------

    //----------------------------------
    // negativeNumberFormat error
    //----------------------------------

    /**
     *  @private
     *  Storage for the negativeNumberFormatError property.
     */
    private var _negativeNumberFormatError:String;
    private var negativeNumberFormatErrorOverride:String;

    [Inspectable(category="Errors", defaultValue="null")]

    /**
     *  Error message when the input number's negative number format is not
     *  following the pattern specified by the negativeNumberFormat property.
     *
     *  @default "The negative format of the input number is incorrect."
     *
     *  @langversion 3.0
     *  @playerversion Flash 10.1
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function get negativeNumberFormatError():String
    {
        return _negativeNumberFormatError;
    }

    public function set negativeNumberFormatError(value:String):void
    {
        negativeNumberFormatErrorOverride = value;

        _negativeNumberFormatError = value ? value :
           resourceManager.getString("validators", "negativeNumberFormatError");
    }


    //--------------------------------------------------------------------------
    //
    //  Overridden Methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     */
    override mx_internal function createWorkingInstance():void
    {
        // release groupingPatternSymbols as it contains grouping symbols based
        // on previous locale grouping pattern.
        groupingPatternSymbols = null;
        createWorkingInstanceCore(NUMBER_VALIDATOR_TYPE);
    }

    /**
     *  @private
     *
     *  Override of the base class <code>doValidation()</code> method
     *  to validate a number.
     *
     *  <p>You do not call this method directly;
     *  Flex calls it as part of performing a validation.
     *  If you create a custom Validator class, you must implement this
     *  method. </p>
     *
     *  @param value Object to validate.
     *
     *  @return An Array of ValidationResult objects, with one ValidationResult
     *  object for each field examined by the validator.
     *
     *  @langversion 3.0
     *  @playerversion Flash 10.1
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    override protected function doValidation(value:Object):Array
    {
        var results:Array = super.doValidation(value);
        
        // Return if there are errors
        // or if the required property is set to <code>false</code> and length
        // is 0.
        var val:String = value ? String(value) : "";
        if (results.length > 0 || ((val.length == 0) && !required))
            return results;
        else
            return validateNumber(value, null);
    }

    /**
     *  Load the error messages from the resource bundle.
     */
    override protected function resourcesChanged():void
    {
        super.resourcesChanged();
        loadChangedResources();
        negativeNumberFormatError = negativeNumberFormatErrorOverride;
    }

    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------

    [Bindable("change")]

    /**
     *  Convenience method for calling a validator from within a custom
     *  validation function. Each of the standard Flex validators has a similar
     *  convenience method. Caller must check the lastOperationStatus after
     *  this.
     *
     *  @param value A number string to validate.
     *
     *  @param baseField Text representation of the subfield specified in the
     *  <code>value</code> object.
     *  For example, if the <code>value</code> parameter specifies value.number,
     *  the <code>baseField</code> value is "number".
     *
     *  @return An Array of ValidationResult objects, with one ValidationResult
     *  object for each field examined by the validator.
     *
     *  @see mx.validators.ValidationResult
     *
     *  @langversion 3.0
     *  @playerversion Flash 10.1
     *  @playerversion AIR 2.5
     *  @productversion Flex 4.5
     */
    public function validateNumber(value:Object,
                                   baseField:String):Array
    {
        const maxValue:Number = Number(maxValue);
        const minValue:Number = Number(minValue);
        const inputStr:String = String(value);

        var results:Array = [];

        // if the input can be a null/empty, return no error.
        if (!inputStr)
            return results;

        // If spark formatter is null, no-go-forward.
        if (!g11nWorkingInstance)
        {
            fallbackLastOperationStatus =
                            LastOperationStatus.LOCALE_UNDEFINED_ERROR;
            return results;
        }

        // g11nWorkingInstance for a locale is available.
        // strip leading and trailing white spaces.
        const input:String = GlobalizationUtils.trim(inputStr);

        const len:int = input.length;

        // NumberValidatorBase has this method. Unlike flash globalization,
        // validator gives error if decimal and grouping separator are same.
        if (!validateNumberFormat(input, results, baseField))
            return results;

        // Parse the number string using the flash globalization NumberFormatter
        const nf:spark.formatters.NumberFormatter =
               g11nWorkingInstance as spark.formatters.NumberFormatter;
        const inputNum:Number = nf.parseNumber(input);

        // parseNumber() only returns PARSE_ERROR if it finds any error in input
        // string. If there is a PARSE_ERROR, validate the input
        // string further, detect and report the error. parse() is lenient than
        // parseNumber() and parses to the extent possible without error. Hence
        // it is not suitable.
        if (nf.lastOperationStatus == LastOperationStatus.PARSE_ERROR)
        {
            if (!detectAndReportProblem(input, baseField, results))
            {
                return results;
            }
            else
            {
                results.push(new ValidationResult(
                    true, baseField, "parseError",
                    parseError));
                return results;
            }
        }

        // See if negative number is allowed.
        if (!validateNumberNegativity(inputNum, baseField, results))
            return results;

        // If grouping separator(s) are present in the input string
        // make sure it's followed by correct number of digits per grouping
        // pattern. We need the original number string extracted from input
        // string with grouping separators intact. If input string has a
        // decimal, then we need the number string upto last digit before the
        // decimal.
        var valStr:String = inputNum.toString();
        if (inputNum < 0)
            valStr = valStr.substring(1);
        const numStart:int = input.indexOf(valStr.charAt(0));
        const numEnd:int = input.lastIndexOf(valStr.charAt(valStr.length-1));
        const decimalSeparatorIndex:Number = input.indexOf(decimalSeparator);
        const end:int = (decimalSeparatorIndex == -1) ? numEnd :
                                                      decimalSeparatorIndex - 1;

        //
        // Make sure every character after the decimal is a digit,
        // and that there aren't too many digits after the decimal point:
        // if domain is int there should be none,
        // otherwise there should be no more than specified by fractionalDigits.
        //
        if (!validateFractionPart(
                            input, decimalSeparatorIndex, baseField, results))
        {
            return results;
        }

        if (!validateGrouping(input.substring(numStart, end), end-numStart))
        {
            results.push(new ValidationResult(
                true, baseField, "groupingSeparation",
                groupingSeparationError));
            return results;
        }

        // Make sure the input is within the specified range.
        // Make sure the input is within the specified range.
        // check the range of the number.
        if (!validateNumberRange(inputNum, baseField, results))
            return results;

        return results;
    }

    //--------------------------------------------------------------------------
    //
    //  Private Methods
    //
    //--------------------------------------------------------------------------

    /**
     *  @private
     *  If there is a parse error by flash.globalization.NumberFormatter, detect
     *  the error and report it for user clarity. parse() method does not return
     *  anything other than PARSE_ERROR.
     */
    private function detectAndReportProblem(input:String, baseField:String,
                                            results:Array):Boolean
    {
        const len:int = input.length;
        // Check for invalid characters in input.
        // One of the negative format of number is enclosing in parenthesis.
        const validChars:String = DECIMAL_DIGITS + "-" + "(" + ")" +
            decimalSeparator + groupingSeparator;

        if (validateInputCharacters(input, len, validChars))
        {
            results.push(new ValidationResult(
                true, baseField, "invalidChar",
                invalidCharError));
            return false;
        }
        // Make sure there's only one decimal point.
        else if (input.indexOf(decimalSeparator) !=
                 input.lastIndexOf(decimalSeparator))
        {
            results.push(new ValidationResult(
                true, baseField, "decimalPointCount",
                decimalPointCountError));
            return false;
        }
        // NumberValidatorBase has this method.
        else if (!validateDecimalString(input, baseField, results))
        {
            return false;
        }
        // all errors are already checked. Only remaining error is
        // negativeNumberFormat.
        else if ((input.indexOf(negativeSymbol) != -1) ||
            ((input.charAt(0) == "(") && (input.charAt(len-1) == ")")))

        {
            results.push(new ValidationResult(
                    true, baseField, "negativeNumberFormat",
                    negativeNumberFormatError));
                return false;
        }
        return true;
    }
}
}
