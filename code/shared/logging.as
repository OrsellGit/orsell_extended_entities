/**
* @brief   Config file of general ConVars for addon.
* @details
* @authors Orsell
*
* @license Distributed under the MIT license.
*/

#include "./debug.as"

/**
* @brief Helper function to convert a Vector to a string.
* @param Vector to convert.
* @return Vector represented with a string.
*/
string VectorToString( const Vector&in vector )
{
    return "({}, {}, {})".format(vector.x, vector.y, vector.z);
}

/**
* @brief Helper function to convert a Color to a string.
* @param Color to convert.
* @return Color represented with a string.
*/
string ColorToString( const Color&in color )
{
    return "({}, {}, {}, {})".format(color.r, color.g, color.b, color.a);
}

/**
* @brief Main debug logging function used for Orsell's Extended Entities.
*        Won't send messages to console if "oee_debug" if 0.
* @param Message to send to console.
* @param Log level. 0 = Info, 1 = Warn
*/
void EELog(const string&in msg, const int level = 0)
{
    if (!oee_debug.GetBool() && level < 1)
        return;

    switch (level)
    {
        case 1:
            Warningl("[OEE] [WARNING] " + msg);
            break;
        case 0:
        default:
            Warningl("[OEE] " + msg);
            break;
    }
}
