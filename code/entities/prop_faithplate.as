/**
* @brief   The usual faith plate setup but now made as a entity that can be placed down and just works.
*! @details WIP STILL! DOESN'T ANIMATE OR OUTPUT FROM TRIGGER! IN GENERAL THIS CODE IS NOT GREAT AND NEEDS CLEAN UP!
* @authors Orsell
*
* @license Distributed under the MIT license.
*/

#include "../core.as"

ConVar extendedents_debug_plates("extendedents_debug_plates", "0");

/**
* @brief Specific logging function for prop_faithplate debugging.
*        Needs "extendedents_debug_plates" to be 1 to log to console.
* @param Message to send to console.
* @param Log level. 0 = Info, 1 = Warn
*/
void EEPlateLog(const string&in msg, const int level = 0)
{
    if (!extendedents_debug_plates.GetBool())
        return;

    EELog("[prop_faithplate] " + msg, level);
}


[ServerCommand("extendedents_plates_flingangle", "")]
void FlingAngle( const CommandArgs@ args )
{
    CBaseEntity@ player = EntityList().FindByClassname(null, "player");
    EEPlateLog("IsPlayer {}".format(player.IsPlayer()));
    player.GetPhysicsObject().SetVelocityInstantaneous(Vector(670,670,670), Vector(-90, 0, 0));
}

[ServerCommand("extendedents_plates_inputs", "Test prop_faithplate using various inputs.")]
void TestPlates( const CommandArgs@ args )
{
    if (args.ArgC() < 2)
    {
        EEPlateLog("extendedents_plates_inputs: Usage 'extendedents_plates_inputs (Input Option) (TempStateTime if 6)\nEnable: 0\nDisable: 1\nToggle: 2\nTempOn: 3\nTempOff: 4\nGetEnabled: 5\nSetTempStateTime: 6", 1);
        return;
    }

    for (CBaseEntity@ ent = null; (@ent = EntityList().FindByClassname(ent, "prop_faithplate")) != null;)
    {
        if (@ent == null)
            continue;

        CPropFaithPlate@ plate = cast<CPropFaithPlate>(ent);
        if (@plate == null)
            continue;

        switch (args.Arg(1).toInt())
        {
            case (0):
            {
                plate.FireInput("Enable", Variant(), 0.0f, null, null);
                break;
            }
            case (1):
            {
                plate.FireInput("Disable", Variant(), 0.0f, null, null);
                break;
            }
            case (2):
            {
                plate.FireInput("Toggle", Variant(), 0.0f, null, null);
                break;
            }
            case (3):
            {
                plate.FireInput("TempOn", Variant(), 0.0f, null, null);
                break;
            }
            case (4):
            {
                plate.FireInput("TempOff", Variant(), 0.0f, null, null);
                break;
            }
            case (5):
            {
                plate.FireInput("GetEnabled", Variant(), 0.0f, null, null);
                break;
            }
            case (6):
            {
                Variant setTempStateTimeVariant;
                setTempStateTimeVariant.SetFloat(args.Arg(2).toFloat());
                plate.FireInput("SetTempStateTime", setTempStateTimeVariant, 0.0f, null, null);
                break;
            }
            default:
            {
                EEPlateLog("Invalid input option passed. 0-6", 1);
                return;
            }
        }
    }
}

Vector CalculateLaunchVector( CBaseEntity@ pVictim, CBaseEntity@ pTarget  )
{
    if (@pVictim == null || @pTarget == null)
    {
        assert(false);
    }

    // Find where we're going
    Vector vecSourcePos = pVictim.GetAbsOrigin();
    Vector vecTargetPos = pTarget.GetAbsOrigin();

    // If victim is player, adjust target position so player's center will hit the target
    if ( pVictim.IsPlayer() )
    {
        vecTargetPos.z -= 32.0f;
    }


    //float flSpeed = (pVictim.IsPlayer()) ? this.kv_playerSpeed : this.kv_physicsSpeed;	// u/sec
    float flSpeed = 670;
    float flGravity = ConVarRef("sv_gravity").GetFloat();

    Vector vecVelocity = (vecTargetPos - vecSourcePos);

    // throw at a constant time
    float time = vecVelocity.Length( ) / flSpeed;
    vecVelocity = vecVelocity * (1.f / time); // CatapultLaunchVelocityMultiplier

    // adjust upward toss to compensate for gravity loss
    vecVelocity.z += flGravity * time * 0.5;

    return vecVelocity;
}

string GetFlingAnimation()
{
    //if (!this.triggerCatapult.GetKeyValue("launchTarget", launchTarget))
    //EEPlateLog("kv_launchTarget: {}".format(this.kv_launchTarget));
    // if (!this.GetKeyValue("launchtarget", this.kv_launchTarget))
    // {
    //     plateLogger.Warn("\"launchTarget\" not defined for CPropFaithPlate!", 1);
    //     return "";
    // }

    //CBaseEntity@ targetEnt = EntityList().FindByName(null, this.kv_launchTarget);
    CBaseEntity@ targetEnt = EntityList().FindByName(null, "faithplate_ent_testtarget2");
    if (@targetEnt == null)
    {
        EEPlateLog("Failed to get \"launchTarget\" from CPropFaithPlate!", 1);
        return "";
    }

    //return ANGLED_ANIM;

    // Very hardcoded type behavior that should be removed later.
    // CBaseEntity@ target = EntityList().FindByName(null, this.kv_launchTarget);
    // assert(@target != null);

    // Calculate the launch angle using the velocity and distance from launch origin to target.
    // Vector velocity = this.triggerCatapult.CalculateLaunchVector(); //! REPLACE WITH THIS WHEN EXPOSED
    //Vector velocity = this.CalculateLaunchVector(this, targetEnt);
    Vector velocity = CalculateLaunchVector(EntityList().FindByClassname(null, "player"), targetEnt);
    velocity.z = EntityList().FindByClassname(null, "player").GetAbsOrigin().z;
    Msgl("Velocity: ({},{},{})".format(velocity.x, velocity.y, velocity.z));


    //Vector launchOriginPos = this.triggerCatapult.GetAbsOrigin();
    Vector launchOriginPos = EntityList().FindByClassname(null, "player").GetAbsOrigin();
    // Vector launchTargetPos = this.triggerCatapult.GetLaunchTarget().GetAbsOrigin(); //! REPLACE WITH THIS WHEN EXPOSED
    Vector launchTargetPos = targetEnt.GetAbsOrigin();

    Vector distanceToTargetVector;
    VectorSubtract(launchTargetPos, launchOriginPos, distanceToTargetVector);

    float dot = DotProduct(velocity, distanceToTargetVector);
    float velocityNorm = sqrt(velocity.x ** 2 + velocity.y ** 2 + velocity.z ** 2);//VectorNormalize(velocity);
    float distanceNorm = sqrt(distanceToTargetVector.x ** 2 + distanceToTargetVector.y ** 2 + distanceToTargetVector.z ** 2);//VectorNormalize(distanceToTargetVector);
    Msgl("velocityNorm: {}".format(velocityNorm));
    Msgl("distanceNorm: {}".format(distanceNorm));
    Msgl("Velocity: ({},{},{})".format(velocity.x, velocity.y, velocity.z));
    Msgl("distanceToTargetVector: ({},{},{})".format(distanceToTargetVector.x, distanceToTargetVector.y, distanceToTargetVector.z));
    //float answer = dot / (velocity * distanceToTargetVector);

    // Get the dot product so it can compared with the degree threshold.

    float angle = acos(dot / (velocityNorm * distanceNorm));

    // Msgl("dot: {}".format(dot));
    // Msgl("angle: {}".format(cos(UPWARDS_FLING_ANIM_DEGREE_THRESHOLD * (3.14159265359/180))));
    // if (fabsf(dot) <= cos(UPWARDS_FLING_ANIM_DEGREE_THRESHOLD * (3.14159265359/180))) // TODO: Replace the degree to radians for the function that does it once it's exposed.
    //     return STRAIGHTUP_ANIM;

    if (angle >= UPWARDS_FLING_ANIM_DEGREE_THRESHOLD)
        return STRAIGHTUP_ANIM;

    return ANGLED_ANIM;
}

[ServerCommand("extendedents_plates_fling", "Test prop_faithplate flinging with its animations and trigger touch behavior.")]
void TestFling( const CommandArgs@ args )
{
    // if (args.ArgC() < 2)
    // {
    //     EEPlateLog("extendedents_plates_fling: Usage 'extendedents_plates_fling (Input Option)\nFling (Based on target position. Used to test 'GetFlingAnimation()'.): 0 Forward Fling: 1 Upward Fling: 2", 1);
    //     return;
    // }

    CPropFaithPlate@ plate = cast<CPropFaithPlate>(EntityList().FindByName(null, "faithplate_ent"));

    //Vector vectorLaunch = CalculateLaunchVector( EntityList().FindByName(null, "player"), EntityList().FindByName(null, "faithplate_ent_testtarget"));
    //EEPlateLog('vectorLaunch: {} {} {}'.format(vectorLaunch.x, vectorLaunch.y, vectorLaunch.z));
    //Msgl("Fling anim: {}".format(GetFlingAnimation()));
    plate.SetSequence(plate.LookupSequence(ANGLED_ANIM));

    // for (CBaseEntity@ ent = null; (@ent = EntityList().FindByClassname(ent, "prop_faithplate")) != null;)
    // {
    //     if (@ent == null)
    //         continue;

    //     CPropFaithPlate@ plate = cast<CPropFaithPlate>(ent);
    //     if (@plate == null)
    //         continue;


    //     Msgl(plate.GetFlingAnimation());

    //     EEPlateLog(plate.LookupSequence(ANGLED_ANIM));
    //     //plate.SetSequence(plate.LookupSequence(STRAIGHTUP_ANIM));
    //     //plate.SetSequence(0);
    //     // switch (args.Arg(1).toInt())
    //     // {
    //     // case (0):
    //     // {
    //     //     string plateAnim = plate.GetFlingAnimation();
    //     //     plate.SetSequence(plate.LookupSequence(plateAnim));
    //     //     break;
    //     // }
    //     // case (1):
    //     // {
    //     //     plate.SetSequence(plate.LookupSequence(ANGLED_ANIM));
    //     //     break;
    //     // }
    //     // case (2):
    //     // {
    //     //     plate.SetSequence(plate.LookupSequence(STRAIGHTUP_ANIM));
    //     //     break;
    //     // }
    //     // default:
    //     //     break;
    //     // }
    // }
}


// ------------------------ ENTITY CONSTANTS ------------------------ \\

// Default faith plate model does not support overgrown states, will need to be changed out by end user.
const string DEFAULT_MODEL = "models/props/faith_plate.mdl";
const string DEFAULT_128MODEL = "models/props/faith_plate_128.mdl";
const string DEFAULT_LAUNCH_SOUND = "Metal_SeafloorCar.BulletImpact";
const string DEFAULT_TICKING_SOUND = "World.RobotNegInteractPitchedUp";

const string IDLE_ANIM = "idle";
const string ANGLED_ANIM = "angled";
const string STRAIGHTUP_ANIM = "straightup";
const string FAST_ANGLED_ANIM = "fast";
const int UPWARDS_FLING_ANIM_DEGREE_THRESHOLD = 70;
const float TEMP_STATE_BLINK_INTERVAL = 0.5f;

enum PlateSkins
{
    CLEAN_ON = 0,
    CLEAN_ORANGE,
    CLEAN_OFF,
    RUST_ON,
    RUST_ORANGE,
    RUST_OFF
}


// ------------------------ ENTITY CLASS ------------------------ \\

[Entity("prop_faithplate")]
class CPropFaithPlate : CBaseAnimating
{
    // ------------------------ ENTITY PRIVATE MEMBERS ------------------------ \\

    // The trigger_catapult that is part of the entity.
    private EHandle<CBaseTrigger> m_pTriggerCatapult; // TODO: Replace with CTriggerCatapult once exposed.

    // env_sprite entity that is used for the faith plate light on top.
    private EHandle<CBaseEntity> m_pPlateSprite;

    // Tracking the faith plates current state.
    private bool m_bFaithPlateState;

    // Future time when the plate will stop being in it's temporary state.
    private float m_GoalTempTime = 0.0f;

    // Set when the temporary state needs to be interrupted by Enable/Disable inputs
    private bool m_InterruptTempState = false;

    private int m_AnimFlingIdle = -1; // Cache the idle animation index.
    private int m_AnimFlingAngled = -1; // Cache the angled animation index.
    private int m_AnimFlingUp = -1; // Cache the upward animation index.
    private int m_AnimFlingFastAngled = -1; // Cache the fast angled animation index.


    // ------------------------ ENTITY KEYVALUE MEMBERS ------------------------ \\

    [KeyValue("startDisabled", FIELD_BOOLEAN)]
    private bool kv_startDisabled; // This is only used at entity spawn to set initial state, faith plate state is tracked by faithPlateState.

    [KeyValue("model", FIELD_MODELNAME)]
    private string kv_modelStr;

    [KeyValue("overgrownEnabled", FIELD_BOOLEAN)]
    private bool kv_overgrownEnabled; // Enable overgrown model.

    [KeyValue("useNewDisableSkin", FIELD_BOOLEAN)]
    private bool kv_useNewDisableSkin; // Len's EverythingPBR faith plate model comes with a off light skin along with the usual blue and orange. Should this off skin be used instead the orange skin?

    [KeyValue("artificialCollision", FIELD_BOOLEAN)]
    private bool kv_artificialCollision; // Vanilla faith plate model comes with no collision by default, so provide artificial collision based on the OBB of the model. If a custom model provides collision, this can be disabled.

    // [KeyValue("faithplate128", FIELD_BOOLEAN)]
    // private bool kv_faithplate128; // If this is the 128 variant of the faith plate or a faith plate model similar that just has a idle and up animation.

    [KeyValue("triggerWidth", FIELD_FLOAT)]
    private float kv_triggerWidth; // Width size of trigger_catapult.

    [KeyValue("triggerDepth", FIELD_FLOAT)]
    private float kv_triggerDepth; // Depth size of trigger_catapult.

    [KeyValue("triggerHeight", FIELD_FLOAT)]
    private float kv_triggerHeight; // Height size of trigger_catapult.

    [KeyValue("triggerPosOffset", FIELD_VECTOR)]
    private Vector kv_triggerPosOffset;

    [KeyValue("addSprite", FIELD_BOOLEAN)]
    private bool kv_addSprite;

    [KeyValue("spriteOnColor", FIELD_VECTOR)]
    private Vector kv_spriteOnColor;

    [KeyValue("spriteOffColor", FIELD_VECTOR)]
    private Vector kv_spriteOffColor;

    [KeyValue("spriteBrightness", FIELD_INTEGER)]
    private int kv_spriteBrightness;

    [KeyValue("playSounds", FIELD_BOOLEAN)]
    private bool kv_playSounds;

    [KeyValue("launchSound", FIELD_SOUNDNAME)]
    private string kv_launchSound;

    [KeyValue("tickingSound", FIELD_SOUNDNAME)]
    private string kv_tickingSound; // Sound used when the temporary on or off inputs are used.

    [KeyValue("tempStateTime", FIELD_FLOAT)]
    private float kv_tempStateTime; // How long the faith plate should stay disable in the temporary off period.

    // ------------------------ TRIGGER_CATAPULT KEYVALUE MEMBERS ------------------------ \\

    [KeyValue("playerspeed", FIELD_FLOAT)]
    private float kv_playerSpeed;

    [KeyValue("physicsspeed", FIELD_FLOAT)]
    private float kv_physicsSpeed;

    [KeyValue("launchdirection", FIELD_VECTOR)]
    private Vector kv_launchDirection;

    [KeyValue("launchtarget", FIELD_STRING)]
    private string kv_launchTarget;

    [KeyValue("useexactvelocity", FIELD_BOOLEAN)]
    private bool kv_useExactVelocity;

    [KeyValue("exactvelocitychoicetype", FIELD_INTEGER)]
    private int kv_exactVelocityChoiceType;

    [KeyValue("applyangularimpulse", FIELD_BOOLEAN)]
    private bool kv_applyAngularImpulse;

    [KeyValue("airctrlsupressiontime", FIELD_FLOAT)]
    private float kv_airCtrlSuppressionTime;

    [KeyValue("DirectionSuppressAirControl", FIELD_BOOLEAN)]
    private bool kv_directionSuppressAirControl;

    [KeyValue("usethresholdcheck", FIELD_BOOLEAN)]
    private bool kv_useThresholdCheck;

    [KeyValue("onlyvelocitycheck", FIELD_BOOLEAN)]
    private bool kv_onlyVelocityCheck;

    [KeyValue("AbsoluteVelocityCheck", FIELD_BOOLEAN)]
    private bool kv_absoluteVelocityCheck;

    [KeyValue("lowerthreshold", FIELD_FLOAT)]
    private float kv_lowerThreshold;

    [KeyValue("upperthreshold", FIELD_FLOAT)]
    private float kv_upperThreshold;

    [KeyValue("entryangletolerance", FIELD_FLOAT)]
    private float kv_entryAngleTolerance;


    // ------------------------ ENTITY OUTPUTS ------------------------ \\

    [Output("OnGetEnabled")]
    private COutputInt out_onGetEnabled;

    [Output("OnEnabled")]
    private COutputEvent out_onEnabled;

    [Output("OnDisabled")]
    private COutputEvent out_onDisabled;

    [Output("OnTempStateEnter")]
    private COutputInt out_onTempEnter;

    [Output("OnTempStateExit")]
    private COutputInt out_onTempExit;

    [Output("OnCatapulted")]
    private COutputEvent out_onCatapulted;

    // ------------------------ ENTITY PRIVATE FUNCTIONS ------------------------ \\

    /**
    * @brief Return the appropriate skin for the faith plate. Specifically made with the faith plate in mind.
    *        Different from the normal GetSkin since it takes into account what skin should be used when enabled and if it's overgrown.
    * @param Is the plate is disabled or enabled.
    * @return Skin index.
    */
    private int RetrieveStateSkin( bool enabled )
    {
        if (enabled)
            return this.kv_overgrownEnabled ? RUST_ON : CLEAN_ON;

        if (kv_useNewDisableSkin)
            return this.kv_overgrownEnabled ? RUST_OFF : CLEAN_OFF;

        return this.kv_overgrownEnabled ? RUST_ORANGE : CLEAN_ORANGE;
    }

    /**
    * @brief Return the animation to play when launching.
    *        Is dependant on the current launch angle calculated using the launch velocity and distance from target.
    * @return If launching at a angle higher than the defined UPWARDS_FLING_ANIM_DEGREE_THRESHOLD,
    *         then it will return a vertical fling animation, else a angled one.
    */
    // string GetFlingAnimation()
    // {
    //     //if (!this.triggerCatapult.GetKeyValue("launchTarget", launchTarget))
    //     // TODO: Inherit trigger_catapult in FGD for entity.
    //     Msgl("kv_launchTarget: {}".format(this.kv_launchTarget));
    //     // if (!this.GetKeyValue("launchtarget", this.kv_launchTarget))
    //     // {
    //     //     plateLogger.Warn("\"launchTarget\" not defined for CPropFaithPlate!", 1);
    //     //     return "";
    //     // }

    //     CBaseEntity@ targetEnt = EntityList().FindByName(null, this.kv_launchTarget);
    //     if (@targetEnt == null)
    //     {
    //         plateLogger.Warn("Failed to get \"launchTarget\" from CPropFaithPlate!", 1);
    //         return "";
    //     }

    //     //return ANGLED_ANIM;

    //     // Very hardcoded type behavior that should be removed later.
    //     CBaseEntity@ target = EntityList().FindByName(null, this.kv_launchTarget);
    //     assert(@target != null);

    //     // Calculate the launch angle using the velocity and distance from launch origin to target.
    //     // Vector velocity = this.triggerCatapult.CalculateLaunchVector(); //! REPLACE WITH THIS WHEN EXPOSED
    //     Vector velocity = this.CalculateLaunchVector(this, target);
    //     Msgl("Velocity: ({},{},{})".format(velocity.x, velocity.y, velocity.z));


    //     Vector launchOriginPos = this.triggerCatapult.GetAbsOrigin();
    //     // Vector launchTargetPos = this.triggerCatapult.GetLaunchTarget().GetAbsOrigin(); //! REPLACE WITH THIS WHEN EXPOSED
    //     Vector launchTargetPos = target.GetAbsOrigin();

    //     Vector distanceToTargetVector;
    //     VectorSubtract(launchTargetPos, launchOriginPos, distanceToTargetVector);

    //     VectorNormalize(velocity);
    //     VectorNormalize(distanceToTargetVector);
    //     Msgl("Velocity: ({},{},{})".format(velocity.x, velocity.y, velocity.z));
    //     Msgl("distanceToTargetVector: ({},{},{})".format(distanceToTargetVector.x, distanceToTargetVector.y, distanceToTargetVector.z));


    //     // Get the dot product so it can compared with the degree threshold.
    //     float dot = DotProduct(velocity, distanceToTargetVector);

    //     Msgl("dot: {}".format(dot));
    //     Msgl("angle: {}".format(cos(UPWARDS_FLING_ANIM_DEGREE_THRESHOLD * (3.14159265359/180))));
    //     if (fabsf(dot) <= cos(UPWARDS_FLING_ANIM_DEGREE_THRESHOLD * (3.14159265359/180))) // TODO: Replace the degree to radians for the function that does it once it's exposed.
    //         return STRAIGHTUP_ANIM;

    //     return ANGLED_ANIM;
    // }


    // ------------------------ ENTITY PUBLIC FUNCTIONS ------------------------ \\

    /**
    * @brief Used to set the faith plate state.
    * @param enabled State plate should be put into.
    * @param activator Activator that called the input which is setting the faith plate state.
    */
    void SetEnabled( const bool enabled, CBaseEntity@ activator = null )
    {
        if (@activator == null)
        {
            EEPlateLog("SetEnable THIS ACTIVATOR");
            @activator = @this;
        }

        // If in temp state, interrupt it.
        if (this.m_GoalTempTime != 0.0f)
        {
            this.m_GoalTempTime = util::GetCurrentTime();
            this.m_InterruptTempState = true;
            EEPlateLog("SetEnable INTERRUPT!");
        }

        this.m_bFaithPlateState = enabled;
        if (this.m_bFaithPlateState)
            this.m_pTriggerCatapult.Get().Enable();
        else
            this.m_pTriggerCatapult.Get().Disable();
        this.SetSkin(this.RetrieveStateSkin(this.m_bFaithPlateState));
        if (this.kv_addSprite)
        {
            if (this.kv_useNewDisableSkin)
                this.m_pPlateSprite.Get().KeyValue("renderamt", enabled ? this.kv_spriteBrightness : "0");
            else
            {
                // TODO: Remove these to strings once converting Vectors to strings is a thing
                string offColor = "{} {} {}".format(this.kv_spriteOffColor.x, this.kv_spriteOffColor.y, this.kv_spriteOffColor.z);
                string onColor = "{} {} {}".format(this.kv_spriteOnColor.x, this.kv_spriteOnColor.y, this.kv_spriteOnColor.z);
                this.m_pPlateSprite.Get().KeyValue("rendercolor", enabled ? onColor : offColor);
            }
        }

        if (enabled)
        {
            EEPlateLog("SetEnable ENABLE");
            this.out_onEnabled.Fire(activator, this, 0.0f);
        }
        else
            this.out_onDisabled.Fire(activator, this, 0.0f);
    }

    /**
    * @brief Used to set the faith plate temporary state.
    * @param Temporary state plate should be put into.
    * @param Activator that called the input which is setting the faith plate temporary state.
    */
    void SetTempState( bool enableState, CBaseEntity@ activator = null )
    {
        if (@activator == null)
        {
            EEPlateLog("SetTempState ACTIVATOR THIS");
            @activator = @this;
        }

        EEPlateLog("SetTempState enableState: {}".format(enableState));
        this.SetEnabled(enableState, activator);
        // Current time + time to be in temporary state = when temporary state ends. Don't set when tempStateTime is negative for forever temporary state.
        if (this.kv_tempStateTime >= 0.0f)
        {
            this.m_GoalTempTime = util::GetCurrentTime() + this.kv_tempStateTime;
            EEPlateLog("SetTempState goalTempTime: {}".format(this.m_GoalTempTime));
        }
        SetThink(ThinkFunc_t(this.PlateTempStateThink), util::GetCurrentTime(), "CPropFaithPlate::PlateTempStateThink");

        this.out_onTempEnter.Fire(enableState ? 1 : 0, activator, this);
    }


    // ------------------------ ENTITY CLASS FUNCTIONS ------------------------ \\

    /**
    * @brief Precaching assets for entity.
    */
    void Precache() override
    {
        if (this.kv_modelStr.empty())
            this.kv_modelStr = DEFAULT_MODEL;
        if (this.kv_launchSound.empty())
            this.kv_launchSound = DEFAULT_LAUNCH_SOUND;
        if (this.kv_tickingSound.empty())
            this.kv_tickingSound = DEFAULT_TICKING_SOUND;

        PrecacheModel(this.kv_modelStr);
        if (this.kv_playSounds)
            PrecacheScriptSound(this.kv_launchSound);
        PrecacheScriptSound(this.kv_tickingSound);
    }

    /**
    * @brief Actions to do when entity is spawned.
    */
    void Spawn() override
    {
        // DEBUG
        {
            EEPlateLog("-----------------------------");
            EEPlateLog('Spawning prop_faithplate with name: {}'.format(this.GetEntityName()));
            EEPlateLog('model: {}'.format(this.kv_modelStr));
            EEPlateLog('overgroundEnabled: {}'.format(this.kv_overgrownEnabled));
            EEPlateLog('playSounds: {}'.format(this.kv_playSounds));
            EEPlateLog('launchSound: {}'.format(this.kv_launchSound));
            EEPlateLog('tickingSound: {}'.format(this.kv_tickingSound));
            EEPlateLog('tempStateTime: {}'.format(this.kv_tempStateTime));
            EEPlateLog('startDisabled: {}'.format(this.kv_startDisabled));
            EEPlateLog("-----------------------------");
        }

        // Precache faith plate assets
        this.Precache();
        CBaseAnimating::Precache();
        CBaseAnimating::Spawn();

        // Setup faith plate model and collision. Those without proper collisions need to rely on their BBOX.
        this.SetModel(this.kv_modelStr);
        if (this.kv_artificialCollision && (this.kv_modelStr == DEFAULT_MODEL || this.kv_modelStr == DEFAULT_128MODEL))
        {
            this.SetSolid(ESolidType::SOLID_BBOX);
            Vector newMaxs = this.CollisionProp().GetOBBMaxs();
            newMaxs.z = 0; // This is assuming that where the origin lies is where the top face of the faith plate is.
            this.CollisionProp().SetCollisionBounds(this.CollisionProp().GetOBBMins(), newMaxs);
        }
        else
            this.SetSolid(ESolidType::SOLID_VPHYSICS);

        IPhysicsObject@ pPhys = @this.VPhysicsInitStatic();
        if (@pPhys == null)
        {
            EELog("Failed to make VPhysics collision for model!", 1);
            return;
        }

        if (this.kv_modelStr == DEFAULT_128MODEL)
        {
            this.m_AnimFlingIdle = this.LookupSequence("BindPose");
            this.m_AnimFlingUp = this.LookupSequence(STRAIGHTUP_ANIM);
        }
        else
        {
            this.m_AnimFlingIdle = this.LookupSequence(IDLE_ANIM);
            this.m_AnimFlingAngled = this.LookupSequence(ANGLED_ANIM);
            this.m_AnimFlingUp = this.LookupSequence(STRAIGHTUP_ANIM);
            this.m_AnimFlingFastAngled = this.LookupSequence(FAST_ANGLED_ANIM);
        }

        // CTriggerCatapult setup
        {
            // TODO: Replace this with separate entity class. Maybe? Might not need to.
            this.m_pTriggerCatapult.Set(util::CreateEntityByNameT<CBaseTrigger>("trigger_catapult"));

            //! This is annoying! There has got to be a better way!
            this.m_pTriggerCatapult.Get().AddSpawnFlags(this.GetSpawnFlags());
            this.m_pTriggerCatapult.Get().KeyValue("playerspeed", this.kv_playerSpeed );
            this.m_pTriggerCatapult.Get().KeyValue("physicsspeed", this.kv_physicsSpeed );
            this.m_pTriggerCatapult.Get().KeyValue("launchdirection", this.kv_launchDirection );
            this.m_pTriggerCatapult.Get().KeyValue("launchtarget", this.kv_launchTarget );
            this.m_pTriggerCatapult.Get().KeyValue("useexactvelocity", this.kv_useExactVelocity );
            this.m_pTriggerCatapult.Get().KeyValue("exactvelocitychoicetype", this.kv_exactVelocityChoiceType );
            this.m_pTriggerCatapult.Get().KeyValue("applyangularimpulse", this.kv_applyAngularImpulse );
            this.m_pTriggerCatapult.Get().KeyValue("airctrlsupressiontime", this.kv_airCtrlSuppressionTime );
            this.m_pTriggerCatapult.Get().KeyValue("DirectionSuppressAirControl", this.kv_directionSuppressAirControl );
            this.m_pTriggerCatapult.Get().KeyValue("usethresholdcheck", this.kv_useThresholdCheck );
            this.m_pTriggerCatapult.Get().KeyValue("onlyvelocitycheck", this.kv_onlyVelocityCheck );
            this.m_pTriggerCatapult.Get().KeyValue("AbsoluteVelocityCheck", this.kv_absoluteVelocityCheck );
            this.m_pTriggerCatapult.Get().KeyValue("lowerthreshold", this.kv_lowerThreshold );
            this.m_pTriggerCatapult.Get().KeyValue("upperthreshold", this.kv_upperThreshold );
            this.m_pTriggerCatapult.Get().KeyValue("entryangletolerance", this.kv_entryAngleTolerance );
            if (this.kv_playSounds)
                this.m_pTriggerCatapult.Get().KeyValue("launchsound", this.kv_launchSound );
            else
                this.m_pTriggerCatapult.Get().KeyValue("launchsound", "" );

            this.m_pTriggerCatapult.Get().KeyValue("OnCatapulted", "{},Catapult,,0,-1".format(this.GetEntityName()));

            this.m_pTriggerCatapult.Get().Spawn();
            this.m_pTriggerCatapult.Get().Activate();
        }

        // DEBUG
        {
            EEPlateLog("-----------------------------");
            EEPlateLog('playerspeed: {}'.format(this.kv_playerSpeed));
            EEPlateLog('launchdirection: {} {} {}'.format(this.kv_launchDirection.x, this.kv_launchDirection.y, this.kv_launchDirection.z));
            EEPlateLog('launchtarget: {}'.format(this.kv_launchTarget));
            EEPlateLog('tempStateTime: {}'.format(this.kv_tempStateTime));
            EEPlateLog('startDisabled: {}'.format(this.kv_startDisabled));
            EEPlateLog('launchsound: {}'.format(this.kv_launchSound));
            EEPlateLog("-----------------------------");
        }


        // Set trigger size using the three KVs, cursed and a tad annoying.
        Vector sizeVector, sizeVectorNegated;
        sizeVectorNegated = sizeVector = Vector(this.kv_triggerWidth, this.kv_triggerDepth, this.kv_triggerHeight) / 2;
        sizeVectorNegated.Negate();
        this.m_pTriggerCatapult.Get().SetCollisionBounds(sizeVectorNegated, sizeVector);
        this.m_pTriggerCatapult.Get().SetMoveType(EMoveType::MOVETYPE_NONE);
        this.m_pTriggerCatapult.Get().SetSolid(ESolidType::SOLID_OBB); // Solidity needs to be based on the OBB because it won't have a model packed in by VBSP.
        this.m_pTriggerCatapult.Get().SetParent(this);

        this.m_pTriggerCatapult.Get().SetAbsOrigin(this.GetAbsOrigin() + this.kv_triggerPosOffset);
        this.m_pTriggerCatapult.Get().SetAbsAngles(this.GetAbsAngles());

        if (this.kv_addSprite)
        {
            // TODO: Remove these to strings once converting Vectors to strings is a thing
            string offColor = "{} {} {}".format(this.kv_spriteOffColor.x, this.kv_spriteOffColor.y, this.kv_spriteOffColor.z);
            string onColor = "{} {} {}".format(this.kv_spriteOnColor.x, this.kv_spriteOnColor.y, this.kv_spriteOnColor.z);
            // TODO: Change to CSprite once it is exposed.
            this.m_pPlateSprite.Set(util::CreateEntityByNameT<CBaseEntity>("env_sprite"));
            this.m_pPlateSprite.Get().KeyValue("rendercolor", this.kv_startDisabled ? offColor : onColor);
            this.m_pPlateSprite.Get().KeyValue("renderamt", this.kv_spriteBrightness);
            this.m_pPlateSprite.Get().KeyValue("rendermode", "9");
            this.m_pPlateSprite.Get().KeyValue("model", "sprites/light_glow02.vmt");
            this.m_pPlateSprite.Get().KeyValue("scale", "0.7");
            this.m_pPlateSprite.Get().KeyValue("GlowProxySize", "5");
            this.m_pPlateSprite.Get().KeyValue("HDRColorScale", "1.0");
            this.m_pPlateSprite.Get().KeyValue("spawnflags", !this.kv_startDisabled);
            this.m_pPlateSprite.Get().Spawn();
            this.m_pTriggerCatapult.Get().Activate();
            this.m_pPlateSprite.Get().SetParent(this);
            this.m_pPlateSprite.Get().SetParentAttachment("light");
        }

        this.m_bFaithPlateState = !this.kv_startDisabled;
        this.SetSkin(RetrieveStateSkin(this.m_bFaithPlateState));
        if (this.m_bFaithPlateState)
            this.m_pTriggerCatapult.Get().Enable();
        else
            this.m_pTriggerCatapult.Get().Disable();
    }

    /**
    * @brief Think function used for both temporary off and on inputs. Makes the plate blink its on and off indicator and emit the sound set ticking.
    */
    void PlateTempStateThink()
    {
        EEPlateLog("-------------");
        EEPlateLog("TEST THINKKKK");
        EEPlateLog("goalTempTime: {}".format(this.m_GoalTempTime));
        EEPlateLog("interruptTempState: {}".format(this.m_InterruptTempState));
        EEPlateLog("GetCurrentTime: {}".format(util::GetCurrentTime()));
        EEPlateLog("this.goalTempTime <= util::GetCurrentTime(): {}".format(this.m_GoalTempTime <= util::GetCurrentTime()));
        EEPlateLog("-------------");

        // End state when goal time has passed. Do not exit when goal is negative as that is used for temp states which go on forever.
        if ((this.m_GoalTempTime <= util::GetCurrentTime()) && kv_tempStateTime > 0.0f || this.m_InterruptTempState)
        {
            SetNextThink(-1, "CPropFaithPlate::PlateTempStateThink");
            this.m_GoalTempTime = 0.0f;

            if (!this.m_InterruptTempState)
                this.SetEnabled(!this.m_bFaithPlateState);

            this.m_InterruptTempState = false;
            this.out_onTempExit.Fire(this.m_bFaithPlateState ? 1 : 0, this, this);
            return;
        }

        // Switch between on and off skin states. Blinks every TEMP_STATE_BLINK_INTERVAL seconds.
        bool blinkOn = (int(util::GetCurrentTime() / TEMP_STATE_BLINK_INTERVAL) % 2) == 0;
        if (!blinkOn)
            this.EmitSound(this.kv_tickingSound);

        this.SetSkin(this.RetrieveStateSkin(blinkOn));
        if (this.kv_addSprite)
        {
            if (this.kv_useNewDisableSkin)
                this.m_pPlateSprite.Get().KeyValue("renderamt", blinkOn ? this.kv_spriteBrightness : "0");
            else
            {
                // TODO: Remove these to strings once converting Vectors to strings is a thing
                string offColor = "{} {} {}".format(this.kv_spriteOffColor.x, this.kv_spriteOffColor.y, this.kv_spriteOffColor.z);
                string onColor = "{} {} {}".format(this.kv_spriteOnColor.x, this.kv_spriteOnColor.y, this.kv_spriteOnColor.z);
                this.m_pPlateSprite.Get().KeyValue("rendercolor", blinkOn ? onColor : offColor);
            }
        }

        SetNextThink(util::GetCurrentTime() + TEMP_STATE_BLINK_INTERVAL, "CPropFaithPlate::PlateTempStateThink");
        EEPlateLog("PlateTempStateThink next think: " + util::GetCurrentTime() + TEMP_STATE_BLINK_INTERVAL);
    }


    // ------------------------ ENTITY INPUT FUNCTIONS ------------------------ \\

    [Input("Enable", FIELD_INPUT)]
    void Enable( const InputData&in data )
    {
        this.SetEnabled(true, data.activator);
    }

    [Input("Disable", FIELD_INPUT)]
    void Disable( const InputData&in data )
    {
        this.SetEnabled(false, data.activator);
    }

    [Input("Toggle", FIELD_INPUT)]
    void Toggle( const InputData&in data )
    {
        this.m_bFaithPlateState = !this.m_bFaithPlateState;
        this.SetEnabled(this.m_bFaithPlateState, data.activator);
    }

    [Input("TempOn", FIELD_INPUT)]
    void TempOn( const InputData&in data )
    {
        EEPlateLog("TEMP ON");
        this.SetTempState(true, data.activator);
    }

    [Input("TempOff", FIELD_INPUT)]
    void TempOff( const InputData&in data )
    {
        EEPlateLog("TEMP OFF");
        this.SetTempState(false, data.activator);
    }

    [Input("GetEnabled", FIELD_INPUT)]
    void GetEnabled( const InputData&in data )
    {
        this.out_onGetEnabled.Fire(this.m_bFaithPlateState ? 1 : 0, data.activator, this);
    }

    [Input("SetTempStateTime", FIELD_INPUT)]
    void SetTempStateTime( const InputData&in data )
    {
        this.kv_tempStateTime = data.value.Float();
    }

    // ------------------------ TRIGGER_CATAPULT INPUT FUNCTIONS ------------------------ \\


    [Input("SetPlayerSpeed", FIELD_FLOAT)]
    void SetPlayerSpeed( const InputData&in data )
    {
        this.kv_playerSpeed = data.value.Float();
        this.m_pTriggerCatapult.Get().KeyValue("playerspeed", this.kv_playerSpeed);
    }

    [Input("SetPhysicsSpeed", FIELD_FLOAT)]
    void SetPhysicsSpeed( const InputData&in data )
    {
        this.kv_physicsSpeed = data.value.Float();
        this.m_pTriggerCatapult.Get().KeyValue("physicsspeed", this.kv_physicsSpeed);
    }

    [Input("SetLaunchTarget", FIELD_STRING)]
    void SetLaunchTarget( const InputData&in data )
    {
        this.kv_launchTarget = data.value.String();
        this.m_pTriggerCatapult.Get().KeyValue("launchtarget", this.kv_launchTarget);
    }

    [Input("SetExactVelocityChoiceType", FIELD_INTEGER)]
    void SetExactVelocityChoiceType( const InputData&in data )
    {
        this.kv_exactVelocityChoiceType = data.value.Int();
        this.m_pTriggerCatapult.Get().KeyValue("exactvelocitychoicetype", this.kv_exactVelocityChoiceType );
    }

    [Input("Catapult", FIELD_INPUT)]
    void InputCatapult( const InputData&in data )
    {
        this.out_onCatapulted.Fire(data.activator, this, 0);

        if (this.kv_modelStr == DEFAULT_128MODEL)
        {
            //this.SetSequence(this.m_AnimFlingUp);
            return;
        }

        // TODO: Calculate launch angle to determine which animation to play.
        //this.SetSequence()
    }
}
