/**
* @brief   Some debug ConCommands.
* @details
* @authors Orsell
*
* @license Distributed under the MIT license.
*/

#include "extendedents_core.as"

[ServerCommand("extendedents_triggers_getsizes", "")]
void GetTriggerSize( const CommandArgs@ args )
{
    for (CBaseEntity@ ent = null; (@ent = EntityList().Next(ent)) != null;)
    {
        if (@ent == null)
            return;

        if (!ent.IsTrigger())
            continue;

        Vector entMinSize = ent.CollisionProp().GetOBBMins();
        Vector entMaxSize = ent.CollisionProp().GetOBBMaxs();
        Vector entSize = ent.CollisionProp().GetOBBSize();
        float entRadius = ent.CollisionProp().GetBoundingRadius();

        EELog("{} | {}".format(ent.GetClassname(), ent.GetEntityName()));
        EELog("IsBSPModel: {}".format(ent.IsBSPModel()));
        EELog("entMinSize: ({}, {}, {}), entMaxSize: ({}, {}, {})".format(entMinSize.x, entMinSize.y, entMinSize.z, entMaxSize.x, entMaxSize.y, entMaxSize.z));
        EELog("size: ({}, {}, {})".format(entSize.x, entSize.y, entSize.z));
        EELog("radius: {}".format(entRadius));
        EELog("--------------------");
    }
}
