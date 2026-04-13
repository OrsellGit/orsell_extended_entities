/**
* @brief   The usual faith plate setup but now made as a entity that can be placed down and just works.
*! @details WIP DOES NOT PROPERLY WORK!
* @authors Orsell
*
* @license Distributed under the MIT license.
*/

#include "../extendedents_core.as"

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
    Msgl("Fling anim: {}".format(GetFlingAnimation()));
    //plate.SetSequence(plate.LookupSequence(ANGLED_ANIM));

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

    [KeyValue("triggerWidth", FIELD_FLOAT)]
    private float kv_triggerWidth;

    [KeyValue("triggerDepth", FIELD_FLOAT)]
    private float kv_triggerDepth;

    [KeyValue("triggerHeight", FIELD_FLOAT)]
    private float kv_triggerHeight;

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
    private COutputInt out_onCatapulted;


    // ------------------------ ENTITY PRIVATE MEMBERS ------------------------ \\

    // The trigger_catapult that is part of the entity.
    private CBaseTrigger@ triggerCatapult = null; // TODO: Replace with CTriggerCatapult once exposed.

    // env_sprite entity that is used for the faith plate light on top.
    private CBaseEntity@ plateSprite = null;

    // Tracking the faith plates current state.
    private bool faithPlateState;

    // Future time when the plate will stop being in it's temporary state.
    private float goalTempTime = 0.0f;

    // Set when the temporary state needs to be interrupted by Enable/Disable inputs
    private bool interruptTempState = false;


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
    * @param State plate should be put into.
    * @param Activator that called the input which is setting the faith plate state.
    */
    void SetEnable( bool enable, CBaseEntity@ activator = null )
    {
        if (@activator == null)
        {
            EEPlateLog("SetEnable THIS ACTIVATOR");
            @activator = @this;
        }

        // If in temp state, interrupt it.
        if (this.goalTempTime != 0.0f)
        {
            this.goalTempTime = util::GetCurrentTime();
            this.interruptTempState = true;
            EEPlateLog("SetEnable INTERRUPT!");
        }

        this.faithPlateState = enable;
        this.triggerCatapult.SetSolid(this.faithPlateState ? ESolidType::SOLID_OBB : ESolidType::SOLID_NONE); // TODO-FIXME: CBaseTrigger Enabled/Disabled wasn't exposed, replace with that when it is.
        this.SetSkin(this.RetrieveStateSkin(this.faithPlateState));
        if (this.kv_useNewDisableSkin)
            this.plateSprite.KeyValue("renderamt", enable ? this.kv_spriteBrightness : "0");
        else
        {
            // TODO: Remove these to strings once converting Vectors to strings is a thing
            string offColor = "{} {} {}".format(this.kv_spriteOffColor.x, this.kv_spriteOffColor.y, this.kv_spriteOffColor.z);
            string onColor = "{} {} {}".format(this.kv_spriteOnColor.x, this.kv_spriteOnColor.y, this.kv_spriteOnColor.z);
            this.plateSprite.KeyValue("rendercolor", enable ? onColor : offColor);
        }

        if (enable)
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
        this.SetEnable(enableState, activator);
        // Current time + time to be in temporary state = when temporary state ends. Don't set when tempStateTime is negative for forever temporary state.
        if (this.kv_tempStateTime >= 0.0f)
        {
            this.goalTempTime = util::GetCurrentTime() + this.kv_tempStateTime;
            EEPlateLog("SetTempState goalTempTime: {}".format(this.goalTempTime));
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

        // Precache faith plate assets
        this.Precache();
        CBaseAnimating::Precache();
        CBaseAnimating::Spawn();

        // Setup faith
        this.SetModel(this.kv_modelStr);
        if (this.kv_artificialCollision)
            this.SetSolid(ESolidType::SOLID_OBB);
        else
            this.SetSolid(ESolidType::SOLID_VPHYSICS);

        // TODO: Replace this with separate entity class. Maybe? Might not need to.
        @this.triggerCatapult = @util::CreateEntityByNameT<CBaseTrigger>("trigger_catapult");

        //! This is annoying! There has got to be a better way!
        this.triggerCatapult.AddSpawnFlags(this.GetSpawnFlags());
        this.triggerCatapult.KeyValue("playerspeed", kv_playerSpeed );
        this.triggerCatapult.KeyValue("physicsspeed", kv_physicsSpeed );
        this.triggerCatapult.KeyValue("launchdirection", kv_launchDirection );
        this.triggerCatapult.KeyValue("launchtarget", kv_launchTarget );
        this.triggerCatapult.KeyValue("useexactvelocity", kv_useExactVelocity );
        this.triggerCatapult.KeyValue("exactvelocitychoicetype", kv_exactVelocityChoiceType );
        this.triggerCatapult.KeyValue("applyangularimpulse", kv_applyAngularImpulse );
        this.triggerCatapult.KeyValue("airctrlsupressiontime", kv_airCtrlSuppressionTime );
        this.triggerCatapult.KeyValue("DirectionSuppressAirControl", kv_directionSuppressAirControl );
        this.triggerCatapult.KeyValue("usethresholdcheck", kv_useThresholdCheck );
        this.triggerCatapult.KeyValue("onlyvelocitycheck", kv_onlyVelocityCheck );
        this.triggerCatapult.KeyValue("AbsoluteVelocityCheck", kv_absoluteVelocityCheck );
        this.triggerCatapult.KeyValue("lowerthreshold", kv_lowerThreshold );
        this.triggerCatapult.KeyValue("upperthreshold", kv_upperThreshold );
        this.triggerCatapult.KeyValue("entryangletolerance", kv_entryAngleTolerance );
        if (this.kv_playSounds)
            this.triggerCatapult.KeyValue("launchsound", kv_launchSound );
        else
             this.triggerCatapult.KeyValue("launchsound", "" );

        this.triggerCatapult.Spawn();

        // DEBUG
        EEPlateLog("-----------------------------");
        EEPlateLog('playerspeed: {}'.format(this.kv_playerSpeed));
        EEPlateLog('launchdirection: {} {} {}'.format(this.kv_launchDirection.x, this.kv_launchDirection.y, this.kv_launchDirection.z));
        EEPlateLog('launchtarget: {}'.format(this.kv_launchTarget));
        EEPlateLog('tempStateTime: {}'.format(this.kv_tempStateTime));
        EEPlateLog('startDisabled: {}'.format(this.kv_startDisabled));
        EEPlateLog('launchsound: {}'.format(this.kv_launchSound));
        EEPlateLog("-----------------------------");

        // Set trigger size using the three KVs, cursed and a tad annoying.
        Vector sizeVector, sizeVectorNegated;
        sizeVectorNegated = sizeVector = Vector(this.kv_triggerWidth, this.kv_triggerDepth, this.kv_triggerHeight) / 2;
        sizeVectorNegated.Negate();
        this.triggerCatapult.SetCollisionBounds(sizeVectorNegated, sizeVector);
        this.triggerCatapult.SetMoveType(EMoveType::MOVETYPE_NONE);
        this.triggerCatapult.SetSolid(ESolidType::SOLID_OBB);
        this.triggerCatapult.SetParent(this);

        this.triggerCatapult.SetAbsOrigin(this.GetAbsOrigin() + this.kv_triggerPosOffset);
        this.triggerCatapult.SetAbsAngles(this.GetAbsAngles());

        if (this.kv_addSprite)
        {
            // TODO: Remove these to strings once converting Vectors to strings is a thing
            string offColor = "{} {} {}".format(this.kv_spriteOffColor.x, this.kv_spriteOffColor.y, this.kv_spriteOffColor.z);
            string onColor = "{} {} {}".format(this.kv_spriteOnColor.x, this.kv_spriteOnColor.y, this.kv_spriteOnColor.z);
            // TODO: Change to CSprite once it is exposed.
            @this.plateSprite = util::CreateEntityByNameT<CBaseEntity>("env_sprite");
            this.plateSprite.KeyValue("rendercolor", this.kv_startDisabled ? offColor : onColor);
            this.plateSprite.KeyValue("renderamt", this.kv_spriteBrightness);
            this.plateSprite.KeyValue("rendermode", "9");
            this.plateSprite.KeyValue("model", "sprites/light_glow02.vmt");
            this.plateSprite.KeyValue("scale", "0.7");
            this.plateSprite.KeyValue("GlowProxySize", "5");
            this.plateSprite.KeyValue("HDRColorScale", "1.0");
            this.plateSprite.KeyValue("spawnflags", !this.kv_startDisabled);
            this.plateSprite.Spawn();
            this.plateSprite.SetParent(this);
            this.plateSprite.SetParentAttachment("light");
        }

        this.faithPlateState = !this.kv_startDisabled;
        this.SetSkin(RetrieveStateSkin(this.faithPlateState));
        // TODO-FIXME: CBaseTrigger Enabled/Disabled wasn't exposed, replace with that when it is.
        this.triggerCatapult.SetSolid(this.faithPlateState ? ESolidType::SOLID_OBB : ESolidType::SOLID_NONE); // Solidity needs to be based on the OBB because it won't have a model packed in by VBSP.
    }

    /**
    * @brief Think function used for both temporary off and on inputs. Makes the plate blink its on and off indicator and emit the sound set ticking.
    */
    void PlateTempStateThink()
    {
        EEPlateLog("-------------");
        EEPlateLog("TEST THINKKKK");
        EEPlateLog("goalTempTime: {}".format(this.goalTempTime));
        EEPlateLog("interruptTempState: {}".format(this.interruptTempState));
        EEPlateLog("GetCurrentTime: {}".format(util::GetCurrentTime()));
        EEPlateLog("this.goalTempTime <= util::GetCurrentTime(): {}".format(this.goalTempTime <= util::GetCurrentTime()));
        EEPlateLog("-------------");

        // End state when goal time has passed. Do not exit when goal is negative as that is used for temp states which go on forever.
        if ((this.goalTempTime <= util::GetCurrentTime()) && kv_tempStateTime > 0.0f || this.interruptTempState)
        {
            SetNextThink(-1, "CPropFaithPlate::PlateTempStateThink");
            this.goalTempTime = 0.0f;

            if (!this.interruptTempState)
                this.SetEnable(!this.faithPlateState);

            this.interruptTempState = false;
            this.out_onTempExit.Fire(this.faithPlateState ? 1 : 0, this, this);
            return;
        }

        // Switch between on and off skin states. Blinks every TEMP_STATE_BLINK_INTERVAL seconds.
        bool blinkOn = (int(util::GetCurrentTime() / TEMP_STATE_BLINK_INTERVAL) % 2) == 0;
        if (!blinkOn)
            this.EmitSound(kv_tickingSound);

        this.SetSkin(this.RetrieveStateSkin(blinkOn));
        if (this.kv_useNewDisableSkin)
            this.plateSprite.KeyValue("renderamt", blinkOn ? this.kv_spriteBrightness : "0");
        else
        {
            // TODO: Remove these to strings once converting Vectors to strings is a thing
            string offColor = "{} {} {}".format(this.kv_spriteOffColor.x, this.kv_spriteOffColor.y, this.kv_spriteOffColor.z);
            string onColor = "{} {} {}".format(this.kv_spriteOnColor.x, this.kv_spriteOnColor.y, this.kv_spriteOnColor.z);
            this.plateSprite.KeyValue("rendercolor", blinkOn ? onColor : offColor);
        }

        SetNextThink(util::GetCurrentTime() + TEMP_STATE_BLINK_INTERVAL, "CPropFaithPlate::PlateTempStateThink");
        EEPlateLog("PlateTempStateThink next think: " + util::GetCurrentTime() + TEMP_STATE_BLINK_INTERVAL);
    }


    // ------------------------ ENTITY INPUT FUNCTIONS ------------------------ \\

    [Input("Enable", FIELD_INPUT)]
    void Enable( const InputData&in data )
    {
        this.SetEnable(true, data.activator);
    }

    [Input("Disable", FIELD_INPUT)]
    void Disable( const InputData&in data )
    {
        this.SetEnable(false, data.activator);
    }

    [Input("Toggle", FIELD_INPUT)]
    void Toggle( const InputData&in data )
    {
        this.faithPlateState = !this.faithPlateState;
        this.SetEnable(this.faithPlateState, data.activator);
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
        this.out_onGetEnabled.Fire(this.faithPlateState ? 1 : 0, data.activator, this);
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
    }

    [Input("SetPhysicsSpeed", FIELD_FLOAT)]
    void SetPhysicsSpeed( const InputData&in data )
    {
        this.kv_physicsSpeed = data.value.Float();
    }

    [Input("SetLaunchTarget", FIELD_STRING)]
    void SetLaunchTarget( const InputData&in data )
    {
        this.kv_launchTarget = data.value.String();
    }

    [Input("SetExactVelocityChoiceType", FIELD_INTEGER)]
    void SetExactVelocityChoiceType( const InputData&in data )
    {
        this.kv_exactVelocityChoiceType = data.value.Int();
    }
}
