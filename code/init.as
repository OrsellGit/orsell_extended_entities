/**
* @brief   Main entree point of Orsell's Extended Entities.
* @details
* @authors Orsell
*
* @license Distributed under the MIT license.
*/

#if SERVER

[LevelInitPreEntity]
void OnLevelInitPreEntity()
{
    Msgl("LOADING OEE SERVER!");
}

[LevelShutdownPreEntity]
void OnLevelShutdownPreEntity()
{
    Msgl("SHUTTING DOWN OEE SERVER!");
}

#include "./server/entities/prop_faithplate.as"

#endif

#if CLIENT

[LevelInitPreEntity]
void OnLevelInitPreEntity()
{
    Msgl("LOADING OEE CLIENT!");
}

[LevelShutdownPreEntity]
void OnLevelShutdownPreEntity()
{
    Msgl("SHUTTING DOWN OEE CLIENT!");
}

#endif

#include "./shared/debug.as"
