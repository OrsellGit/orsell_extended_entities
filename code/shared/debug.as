/**
* @brief   Debug ConVars and ConCommands for OEE.
* @details
* @authors Orsell
*
* @license Distributed under the MIT license.
*/

#include "./logging.as"

ConVar oee_debug("oee_debug", "1"); // TODO-FIXME: Remember to change this to 0 on release.

#if SERVER

[ServerCommand("oee_triggers_getsizes", "")]
void GetTriggerSize( const CommandArgs@ args )
{
    for (CBaseEntity@ ent = EntityList().First(); (@ent = @EntityList().Next(ent)) !is null;)
    {
        if (ent is null)
            return;

        if (!ent.IsTrigger())
            continue;

        Vector entMinSize = ent.CollisionProp().GetOBBMins();
        Vector entMaxSize = ent.CollisionProp().GetOBBMaxs();
        Vector entSize = ent.CollisionProp().GetOBBSize();
        float entRadius = ent.CollisionProp().GetBoundingRadius();

        EELog("{} | {}".format(ent.GetClassname(), ent.GetDebugName()));
        EELog("IsBSPModel: {}".format(ent.IsBSPModel()));
        EELog("entMinSize: ({}, {}, {}), entMaxSize: ({}, {}, {})".format(entMinSize.x, entMinSize.y, entMinSize.z, entMaxSize.x, entMaxSize.y, entMaxSize.z));
        EELog("size: ({}, {}, {})".format(entSize.x, entSize.y, entSize.z));
        EELog("radius: {}".format(entRadius));
        EELog("--------------------");
    }
}

#endif
