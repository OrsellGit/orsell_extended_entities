/**
* @brief   assert function implementation.
* @details There is no proper assert function for AngelScript, so this is a small implementation that will throw then there is a error.
* @authors Orsell
*
* @license Distributed under the MIT license - Copyright (c) 2026 Project Collapse Studios
*/

/**
* @brief Assertion function to test statements. Will print out if a exception occurs and the error involved.
*        Very limited to what line the assert was called on however.
* @param testStatement Statement to pass in that should be true, if false, then a throw call will be passed.
* @param errMsg Error message that throw should pass when the statement to test fails.
*/
void assert( const bool testStatement, const string&in errMsg = "Passed statement was false!" )
{
    if (!testStatement)
    {
        throw("Assertion hit! Error: " + errMsg);
    }
}
