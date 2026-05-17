/**
* @brief   Main entree point of Orsell's Extended Entities.
* @details
* @authors Orsell
*
* @license Distributed under the MIT license.
*/

[LevelInitPreEntity]
void OnLevelInitPreEntity()
{
    Msgl("LOADING OEE!");
}

// TODO: Properly separate out things that should just be on the client like debug vs stuff on the server like entities.
#if SERVER

#include "debug.as"

#include "entities/prop_faithplate.as"

#endif