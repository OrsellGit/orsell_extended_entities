/**
* @brief   Config file of general ConVars for addon.
* @details
* @authors Orsell
*
* @license Distributed under the MIT license.
*/

#include "./debug.as"

/**
* @brief Main debug logging function used for Orsell's Extended Entities.
*        Won't send messages to console if "oee_debug" if 0.
* @param Message to send to console.
* @param Log level. 0 = Info, 1 = Warn
*/
void EELog(const string&in msg, const int level = 0)
{
    if (!oee_debug.GetBool())
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
