/**
* @brief   Some core functions and ConVars used throughout every file.
* @details
* @authors Orsell
*
* @license Distributed under the MIT license.
*/

#include "assert.as"
#include "logger.as"

ConVar extendedents_debug("extendedents_debug", "0");
Logger EELogger("Extended Entities");

/**
* @brief Main debug logging function used for Orsell's Extended Entities.
*        Won't send messages to console if "extendedents_debug" if 0.
* @param Message to send to console.
* @param Log level. 0 = Info, 1 = Warn
*/
void EELog(const string&in msg, const int level = 0)
{
    if (!extendedents_debug.GetBool())
        return;

    switch (level)
    {
        case 0:
            EELogger.Info(msg);
            break;
        case 1:
            EELogger.Warn(msg);
            break;
        default:
            EELogger.Info(msg);
            break;
    }
}
