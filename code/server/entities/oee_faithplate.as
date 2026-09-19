/**
* @brief   A normal faith plate setup that allows for more customization and other settings.
*! @details WIP! Code still needs some clean up!
* @authors Orsell
*
* @license Distributed under the MIT license.
*/

#include "../../shared/assert.as"
#include "../../shared/debug.as"
#include "../../shared/logging.as"

ConVar oee_debug_plates("oee_debug_plates", "0");

/**
* @brief Specific logging function for oee_faithplate debugging.
*        Needs "oee_debug_plates" to be 1 to log to console.
* @param Message to send to console.
* @param Log level. 0 = Info, 1 = Warn
*/
void EEPlateLog(const string&in msg, const int level = 0)
{
    if (!oee_debug_plates.GetBool() && level < 1)
        return;

    EELog("[CPropFaithPlate] " + msg, level);
}

[ServerCommand("oee_plates_inputs", "Test oee_faithplate using various inputs.")]
void TestPlates( const CommandArgs@ args )
{
    if (args.ArgC() < 2)
    {
        EEPlateLog("oee_plates_inputs: Usage 'oee_plates_inputs (Input Option) (TempStateTime if 6)\nEnable: 0\nDisable: 1\nToggle: 2\nTempOn: 3\nTempOff: 4\nGetEnabled: 5\nSetTempStateTime: 6", 1);
        return;
    }

    for (CBaseEntity@ ent = null; (@ent = @EntityList().FindByClassname(ent, "oee_faithplate")) !is null;)
    {
        if (ent is null)
            continue;

        CPropFaithPlate@ plate = cast<CPropFaithPlate>(ent);
        if (plate is null)
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

// Constants -----------------------

// Default faith plate model does not support overgrown states, will need to be changed out by end user.
const string DEFAULT_MODEL = "models/props/faith_plate.mdl";
const string DEFAULT_128MODEL = "models/props/faith_plate_128.mdl";
const string DEFAULT_LAUNCH_SOUND = "Metal_SeafloorCar.BulletImpact";
const string DEFAULT_TICKING_SOUND = "World.RobotNegInteractPitchedUp";

array<string>@ IDLE_ANIMS =
{
    "idle",
    "ref",
    "bindpose"
};

const string ANGLED_ANIM = "angled";
const string FAST_ANGLED_ANIM = "fast";
const string STRAIGHTUP_ANIM = "straightup";
const string FAST_STRAIGHTUP_ANIM = "fastup";
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

// ---------------------------------------------

// Entity Class -----------------------

[Entity("oee_faithplate")]
class CPropFaithPlate : CBaseAnimating
{

// Save/Restored Members -----------------------

// TODO: Add save/restore fields for all these!

    // The trigger_catapult that is part of the entity.
    private EHandle<CBaseTrigger> m_pTriggerCatapult; // TODO: Replace with CTriggerCatapult once exposed.

    // env_sprite entity that is used for the faith plate light on top.
    private EHandle<CBaseEntity> m_pPlateSprite;

    // Tracking the faith plates current state.
    private bool m_bFaithPlateState = false;

    // Future time when the plate will stop being in it's temporary state.
    private float m_fGoalTempTime = 0.0f;

    // Set when the temporary state needs to be interrupted by Enable/Disable inputs.
    private bool m_bInterruptTempState = false;

    // Used to track when to play the blink sound.
    private bool m_bPreviousBlinkOn = true;

    private int m_iAnimFlingIdle = -1; // Cache the idle animation index.
    private int m_iAnimFlingAngled = -1; // Cache the angled animation index.
    private int m_iAnimFlingUp = -1; // Cache the upward animation index.
    private int m_iAnimFlingFastAngled = -1; // Cache the fast angled animation index.
    private int m_iAnimFlingFastUp = -1; // Cache the fast angled animation index.

    // Used to track what objects have been catapulted and are still in the air to know when to stop the fling music.
    private array<CBaseEntity@>@ m_aCatapultedObjects;

// ---------------------------------------------

// KeyValue Members ----------------------------

    [KeyValue("startDisabled", FIELD_BOOLEAN)]
    private bool kv_bStartDisabled; // This is only used at entity spawn to set initial state, faith plate state is tracked by faithPlateState.

    [KeyValue("model", FIELD_MODELNAME)]
    private string kv_sModel;

    [KeyValue("overgrownEnabled", FIELD_BOOLEAN)]
    private bool kv_bOvergrown; // Enable overgrown model.

    [KeyValue("useNewDisableSkin", FIELD_BOOLEAN)]
    private bool kv_bUseNewDisableSkin; // Len's EverythingPBR faith plate model comes with a off light skin along with the usual blue and orange. Should this off skin be used instead the orange skin?

    [KeyValue("artificialCollision", FIELD_BOOLEAN)]
    private bool kv_bArtificialCollision; // Vanilla faith plate model comes with no collision by default, so provide artificial collision based on the OBB of the model. If a custom model provides collision, this can be disabled.

    [KeyValue("forceUpAnimation", FIELD_BOOLEAN)]
    private bool kv_bForceUpAnimation; // Force using up animation instead of determining animation by target angle.

    [KeyValue("fastAnimation", FIELD_BOOLEAN)]
    private bool kv_bFastAnimation; // Enable to use the fast variants instead of the standard angled or up animations.

    [KeyValue("triggerWidth", FIELD_FLOAT)]
    private float kv_fTriggerWidth; // Width size of trigger_catapult.

    [KeyValue("triggerDepth", FIELD_FLOAT)]
    private float kv_fTriggerDepth; // Depth size of trigger_catapult.

    [KeyValue("triggerHeight", FIELD_FLOAT)]
    private float kv_fTriggerHeight; // Height size of trigger_catapult.

    [KeyValue("triggerPosOffset", FIELD_VECTOR)]
    private Vector kv_vTriggerPosOffset; // Position offset from the origin where the trigger should go.

    [KeyValue("addSprite", FIELD_BOOLEAN)]
    private bool kv_bAddSprite; // Add sprite attached to a faith plate's "light" attachment point on the model. This isn't available for the vanilla model but Len's EverythingPBR faith plate model does have it.

    [KeyValue("spriteOnColor", FIELD_COLOR32)]
    private Color kv_vSpriteOnColor; // Color for the sprite when the faith plate is enabled.

    [KeyValue("spriteOffColor", FIELD_COLOR32)]
    private Color kv_vSpriteOffColor; // Color for the sprite when the faith plate is disabled;

    [KeyValue("spriteBrightness", FIELD_INTEGER)]
    private int kv_iSpriteBrightness; // Brightness of the sprite.

    [KeyValue("playSounds", FIELD_BOOLEAN)]
    private bool kv_bPlaySounds; // If launch sounds should be played by the entity rather than the model.

    [KeyValue("launchSound", FIELD_SOUNDNAME)]
    private string kv_sLaunchSound; // Sound used when objects are launched by the faith plate.

    [KeyValue("tickingSound", FIELD_SOUNDNAME)]
    private string kv_sTickingSound; // Sound used when the temporary on or off inputs are used.

    [KeyValue("launchMusicTrackPlayer", FIELD_SOUNDNAME)]
    private string kv_sLaunchMusicTrackPlayer; // Music track played when player is catapulted.

    [KeyValue("launchMusicTrackPhysics", FIELD_SOUNDNAME)]
    private string kv_sLaunchMusicTrackPhysics; // Music track played when player is catapulted.

    [KeyValue("tempStateTime", FIELD_FLOAT)]
    private float kv_fTempStateTime; // How long the faith plate should stay disable in the temporary off period.

    // TODO: Implement.
    [KeyValue("dragRemoval", FIELD_BOOLEAN)]
    private bool kv_bRemoveDrag; // How long the faith plate should stay disable in the temporary off period.

// ---------------------------------------------

// trigger_catapult KeyValue Members ----------------------------

    [KeyValue("playerspeed", FIELD_FLOAT)]
    private float kv_fPlayerSpeed;

    [KeyValue("physicsspeed", FIELD_FLOAT)]
    private float kv_fPhysicsSpeed;

    [KeyValue("launchdirection", FIELD_VECTOR)]
    private Vector kv_vLaunchDirection;

    [KeyValue("launchtarget", FIELD_STRING)]
    private string kv_sLaunchTarget;

    [KeyValue("useexactvelocity", FIELD_BOOLEAN)]
    private bool kv_bUseExactVelocity;

    [KeyValue("exactvelocitychoicetype", FIELD_INTEGER)]
    private int kv_iExactVelocityChoiceType;

    [KeyValue("applyangularimpulse", FIELD_BOOLEAN)]
    private bool kv_bApplyAngularImpulse;

    [KeyValue("airctrlsupressiontime", FIELD_FLOAT)]
    private float kv_fAirCtrlSuppressionTime;

    [KeyValue("DirectionSuppressAirControl", FIELD_BOOLEAN)]
    private bool kv_bDirectionSuppressAirControl;

    [KeyValue("usethresholdcheck", FIELD_BOOLEAN)]
    private bool kv_bUseThresholdCheck;

    [KeyValue("onlyvelocitycheck", FIELD_BOOLEAN)]
    private bool kv_bOnlyVelocityCheck;

    [KeyValue("AbsoluteVelocityCheck", FIELD_BOOLEAN)]
    private bool kv_bAbsoluteVelocityCheck;

    [KeyValue("lowerthreshold", FIELD_FLOAT)]
    private float kv_fLowerThreshold;

    [KeyValue("upperthreshold", FIELD_FLOAT)]
    private float kv_fUpperThreshold;

    [KeyValue("entryangletolerance", FIELD_FLOAT)]
    private float kv_fEntryAngleTolerance;

// ---------------------------------------------

// Outputs -------------------------------------

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

    [Output("OnCatapultedPlayer")]
    private COutputEvent out_onCatapultedPlayer;

// ---------------------------------------------

// Inputs -------------------------------------

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
        this.kv_fTempStateTime = data.value.Float();
    }

// ---------------------------------------------

// trigger_catapult Inputs -------------------------------------

    [Input("SetPlayerSpeed", FIELD_FLOAT)]
    void SetPlayerSpeed( const InputData&in data )
    {
        this.kv_fPlayerSpeed = data.value.Float();
        Variant setPlayerSpeedVal;
        setPlayerSpeedVal.SetFloat(this.kv_fPlayerSpeed);
        this.m_pTriggerCatapult.Get().FireInput("SetPlayerSpeed", setPlayerSpeedVal, 0.0f, data.activator, data.caller);
    }

    [Input("SetPhysicsSpeed", FIELD_FLOAT)]
    void SetPhysicsSpeed( const InputData&in data )
    {
        this.kv_fPhysicsSpeed = data.value.Float();
        Variant setPhysicsSpeedVal;
        setPhysicsSpeedVal.SetFloat(this.kv_fPhysicsSpeed);
        this.m_pTriggerCatapult.Get().FireInput("SetPhysicsSpeed", setPhysicsSpeedVal, 0.0f, data.activator, data.caller);
    }

    [Input("SetLaunchTarget", FIELD_STRING)]
    void SetLaunchTarget( const InputData&in data )
    {
        this.kv_sLaunchTarget = data.value.String();
        Variant setLaunchTargetVal;
        setLaunchTargetVal.SetString(this.kv_sLaunchTarget);
        this.m_pTriggerCatapult.Get().FireInput("SetLaunchTarget", setLaunchTargetVal, 0.0f, data.activator, data.caller);
    }

    [Input("SetExactVelocityChoiceType", FIELD_INTEGER)]
    void SetExactVelocityChoiceType( const InputData&in data )
    {
        this.kv_iExactVelocityChoiceType = data.value.Int();
        Variant setExactVelocityChoiceTypeVal;
        setExactVelocityChoiceTypeVal.SetInt(this.kv_iExactVelocityChoiceType);
        this.m_pTriggerCatapult.Get().FireInput("SetExactVelocityChoiceType", setExactVelocityChoiceTypeVal, 0.0f, data.activator, data.caller);
    }

    //? Not suppose to be directly inputted on the entity! Meant for when the trigger_catapults catapults and sends a input into this entity. Will be combined later.
    [Input("Catapult", FIELD_INPUT)]
    void InputCatapult( const InputData&in data )
    {
        if (data.activator is null)
            return;

        // Player launch track should be globally heard while the physics track is applied to the object getting launched
        if (data.activator.IsPlayer())
        {
            if (!this.kv_sLaunchMusicTrackPlayer.empty())
                data.activator.EmitSound(this.kv_sLaunchMusicTrackPlayer);
            this.out_onCatapultedPlayer.Fire(data.activator, this, 0.0f);
        }
        else
        {
            if (!this.kv_sLaunchMusicTrackPhysics.empty())
                data.activator.EmitSound(this.kv_sLaunchMusicTrackPhysics);
        }

        //EHandle<CBaseEntity> handle;
        //handle.Set(data.activator);
        //this.m_aCatapultedObjects.insertLast(data.activator);
        EEPlateLog("Added entity '{}' with index '{}' to launch list.".format(data.activator.GetDebugName(), data.activator.GetEntityIndex()));

        this.out_onCatapulted.Fire(data.activator, this, 0.0f);

        // TODO: Add launch angle calculation function here.
        bool isAngledUp = this.kv_bForceUpAnimation;// || ;

        if (isAngledUp)
        {
            this.ResetSequence(this.kv_bFastAnimation ? this.m_iAnimFlingFastUp : this.m_iAnimFlingUp);
            return;
        }

        this.ResetSequence(this.kv_bFastAnimation ? this.m_iAnimFlingFastAngled : this.m_iAnimFlingAngled);
    }

// ---------------------------------------------

// Private Functions -------------------------------------

    /**
    * @brief Return the appropriate skin for the faith plate. Specifically made with the faith plate in mind.
    *        Different from the normal GetSkin since it takes into account what skin should be used when enabled and if it's overgrown.
    * @param Is the plate is disabled or enabled.
    * @return Skin index.
    */
    private int RetrieveStateSkin( bool enabled )
    {
        if (enabled)
            return this.kv_bOvergrown ? RUST_ON : CLEAN_ON;

        if (kv_bUseNewDisableSkin)
            return this.kv_bOvergrown ? RUST_OFF : CLEAN_OFF;

        return this.kv_bOvergrown ? RUST_ORANGE : CLEAN_ORANGE;
    }

// ---------------------------------------------

// Public Functions -------------------------------------

    /**
    * @brief Used to set the faith plate state.
    * @param enabled State plate should be put into.
    * @param activator Activator that called the input which is setting the faith plate state.
    */
    void SetEnabled( const bool enabled, CBaseEntity@ activator = null )
    {
        if (activator is null)
        {
            EEPlateLog("SetEnable THIS ACTIVATOR");
            @activator = @this;
        }

        // If in temp state, interrupt it.
        if (this.m_fGoalTempTime != 0.0f)
        {
            this.m_fGoalTempTime = util::GetCurrentTime();
            this.m_bInterruptTempState = true;
            EEPlateLog("SetEnable INTERRUPT!");
        }

        this.m_bFaithPlateState = enabled;
        if (this.m_bFaithPlateState)
            this.m_pTriggerCatapult.Get().Enable();
        else
            this.m_pTriggerCatapult.Get().Disable();
        this.SetSkin(this.RetrieveStateSkin(this.m_bFaithPlateState));
        if (this.kv_bAddSprite && this.m_pPlateSprite.IsValid())
        {
            if (this.kv_bUseNewDisableSkin)
                this.m_pPlateSprite.Get().KeyValue("renderamt", enabled ? this.kv_iSpriteBrightness : "0");
            else
            {
                // TODO: Remove these to strings once converting Vectors to strings is a thing
                string offColor = "{} {} {}".format(this.kv_vSpriteOffColor.r, this.kv_vSpriteOffColor.g, this.kv_vSpriteOffColor.b);
                string onColor = "{} {} {}".format(this.kv_vSpriteOnColor.r, this.kv_vSpriteOnColor.g, this.kv_vSpriteOnColor.b);
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
        if (activator is null)
        {
            EEPlateLog("SetTempState ACTIVATOR THIS");
            @activator = @this;
        }

        EEPlateLog("SetTempState enableState: {}".format(enableState));
        this.SetEnabled(enableState, activator);

        // Current time + time to be in temporary state = when temporary state ends. Don't set when tempStateTime is negative for forever temporary state.
        if (this.kv_fTempStateTime >= 0.0f)
        {
            this.m_fGoalTempTime = util::GetCurrentTime() + this.kv_fTempStateTime;
            EEPlateLog("SetTempState goalTempTime: {}".format(this.m_fGoalTempTime));
        }

        this.out_onTempEnter.Fire(enableState ? 1 : 0, activator, this);
    }

// ---------------------------------------------

// Public Entity class Functions -------------------------------------

    /**
    * @brief Precaching assets for entity.
    */
    void Precache() override
    {
        if (this.kv_sModel.empty())
            this.kv_sModel = DEFAULT_MODEL;
        if (this.kv_sLaunchSound.empty())
            this.kv_sLaunchSound = DEFAULT_LAUNCH_SOUND;
        if (this.kv_sTickingSound.empty())
            this.kv_sTickingSound = DEFAULT_TICKING_SOUND;

        PrecacheModel(this.kv_sModel);
        PrecacheScriptSound(this.kv_sTickingSound);
        if (this.kv_bPlaySounds)
            PrecacheScriptSound(this.kv_sLaunchSound);
        if (!this.kv_sLaunchMusicTrackPlayer.empty())
            PrecacheScriptSound(this.kv_sLaunchMusicTrackPlayer);
        if (!this.kv_sLaunchMusicTrackPhysics.empty())
            PrecacheScriptSound(this.kv_sLaunchMusicTrackPhysics);
    }

    /**
    * @brief Actions to do when entity is spawned.
    */
    void Spawn() override
    {
        // DEBUG
        {
            EEPlateLog("-----------------------------");
            EEPlateLog('Spawning oee_faithplate with name: {}'.format(this.GetDebugName()));
            EEPlateLog('model: {}'.format(this.kv_sModel));
            EEPlateLog('overgroundEnabled: {}'.format(this.kv_bOvergrown));
            EEPlateLog('playSounds: {}'.format(this.kv_bPlaySounds));
            EEPlateLog('launchSound: {}'.format(this.kv_sLaunchSound));
            EEPlateLog('tickingSound: {}'.format(this.kv_sTickingSound));
            EEPlateLog('tempStateTime: {}'.format(this.kv_fTempStateTime));
            EEPlateLog('startDisabled: {}'.format(this.kv_bStartDisabled));
            EEPlateLog("-----------------------------");
        }

        CBaseAnimating::Spawn();
        this.Precache();

        // Setup faith plate model and collision. Those without proper collisions need to rely on their BBOX.
        this.SetModel(this.kv_sModel);
        // TODO-FIXME: Check is a kinda silly return to this and make it nicer.
        if (this.kv_bArtificialCollision && (this.kv_sModel == DEFAULT_MODEL || this.kv_sModel == DEFAULT_128MODEL))
        {
            this.SetSolid(ESolidType::SOLID_BBOX);
            Vector newMaxs = this.CollisionProp().GetOBBMaxs();
            newMaxs.z = 0; // This is assuming that where the origin lies is where the top face of the faith plate is.
            this.CollisionProp().SetCollisionBounds(this.CollisionProp().GetOBBMins(), newMaxs);
        }
        else
            this.SetSolid(ESolidType::SOLID_VPHYSICS);

        // While we are initializing static physics for the model, if it has a parent, the engine will instead make a physics object that can effect other objects but objects can't effect it.
        IPhysicsObject@ pPhys = @this.VPhysicsInitStatic();
        if (pPhys is null)
        {
            EEPlateLog("Failed to make VPhysics collision for model on oee_faithplate with name '{}' and index '{}'!".format(this.GetDebugName(), this.GetEntityIndex()), 1);
            return;
        }

        // Cache animation indexes to be played later.
        for (uint i = 0; i < IDLE_ANIMS.length(); i++)
        {
            this.m_iAnimFlingIdle = this.LookupSequence(IDLE_ANIMS[i]);
            if (this.m_iAnimFlingIdle != -1)
                break;
        }
        if (this.m_iAnimFlingIdle == -1)
            EEPlateLog("Failed to retrieve idle animation for oee_faithplate with name '{}' and index '{}'!".format(this.GetDebugName(), this.GetEntityIndex()), 1);

        this.m_iAnimFlingAngled = this.LookupSequence(ANGLED_ANIM);
        if (this.m_iAnimFlingAngled == -1)
            EEPlateLog("Failed to retrieve angled animation for oee_faithplate with name '{}' and index '{}'!".format(this.GetDebugName(), this.GetEntityIndex()), 1);

        this.m_iAnimFlingFastAngled = this.LookupSequence(FAST_ANGLED_ANIM);
        if (this.m_iAnimFlingFastAngled == -1)
            EEPlateLog("Failed to retrieve fast angled animation for oee_faithplate with name '{}' and index '{}'!".format(this.GetDebugName(), this.GetEntityIndex()), 1);

        this.m_iAnimFlingUp = this.LookupSequence(STRAIGHTUP_ANIM);
        if (this.m_iAnimFlingUp == -1)
            EEPlateLog("Failed to retrieve fling up animation for oee_faithplate with name '{}' and index '{}'!".format(this.GetDebugName(), this.GetEntityIndex()), 1);

        this.m_iAnimFlingFastAngled = this.LookupSequence(FAST_STRAIGHTUP_ANIM);
        if (this.m_iAnimFlingFastUp == -1)
            EEPlateLog("Failed to retrieve fast up animation for oee_faithplate with name '{}' and index '{}'!".format(this.GetDebugName(), this.GetEntityIndex()), 1);

        this.SetPlaybackRate(1.0f);
        this.ResetSequence(this.m_iAnimFlingIdle);

        // CTriggerCatapult setup
        {
            // TODO: Replace this with separate entity class similar to prop_floor_button. Maybe? Might not need to.
            CBaseTrigger@ trigger = util::CreateEntityByNameT<CBaseTrigger>("trigger_catapult");

            //! This is annoying! There has got to be a better way!
            trigger.AddSpawnFlags(this.GetSpawnFlags());
            trigger.KeyValue("playerspeed", this.kv_fPlayerSpeed );
            trigger.KeyValue("physicsspeed", this.kv_fPhysicsSpeed );
            trigger.KeyValue("launchdirection", this.kv_vLaunchDirection );
            trigger.KeyValue("launchtarget", this.kv_sLaunchTarget );
            trigger.KeyValue("useexactvelocity", this.kv_bUseExactVelocity );
            trigger.KeyValue("exactvelocitychoicetype", this.kv_iExactVelocityChoiceType );
            trigger.KeyValue("applyangularimpulse", this.kv_bApplyAngularImpulse );
            trigger.KeyValue("airctrlsupressiontime", this.kv_fAirCtrlSuppressionTime );
            trigger.KeyValue("DirectionSuppressAirControl", this.kv_bDirectionSuppressAirControl );
            trigger.KeyValue("usethresholdcheck", this.kv_bUseThresholdCheck );
            trigger.KeyValue("onlyvelocitycheck", this.kv_bOnlyVelocityCheck );
            trigger.KeyValue("AbsoluteVelocityCheck", this.kv_bAbsoluteVelocityCheck );
            trigger.KeyValue("lowerthreshold", this.kv_fLowerThreshold );
            trigger.KeyValue("upperthreshold", this.kv_fUpperThreshold );
            trigger.KeyValue("entryangletolerance", this.kv_fEntryAngleTolerance );
            if (this.kv_bPlaySounds)
                trigger.KeyValue("launchsound", this.kv_sLaunchSound );
            else
                trigger.KeyValue("launchsound", "" );

            // In order to make this trigger output to this entity, use a KV trick to add a I/O element that will pass OnCatapulted calls to this entity.
            // TODO-FIXME: If a entity if not named, then this input can effect all unnamed faith plates!
            trigger.KeyValue("OnCatapulted", "{},Catapult,,0,-1".format(this.GetDebugName()));

            trigger.Spawn();
            trigger.Activate();
            this.m_pTriggerCatapult.Set(trigger);

            // Set trigger size using the three KVs, this is a tad annoying. Hopefully, a better helper will be implemented later to allow for vector input.
            Vector sizeVector, sizeVectorNegated;
            sizeVectorNegated = sizeVector = Vector(this.kv_fTriggerWidth, this.kv_fTriggerDepth, this.kv_fTriggerHeight) / 2;
            sizeVectorNegated.Negate();
            this.m_pTriggerCatapult.Get().SetAbsOrigin(this.GetAbsOrigin() + this.kv_vTriggerPosOffset);
            this.m_pTriggerCatapult.Get().SetAbsAngles(this.GetAbsAngles());
            this.m_pTriggerCatapult.Get().SetCollisionBounds(sizeVectorNegated, sizeVector);
            this.m_pTriggerCatapult.Get().SetSolid(ESolidType::SOLID_OBB);
            this.m_pTriggerCatapult.Get().SetParent(this);
        }

        // DEBUG
        {
            EEPlateLog("-----------------------------");
            EEPlateLog('playerspeed: {}'.format(this.kv_fPlayerSpeed));
            EEPlateLog('launchdirection: {} {} {}'.format(this.kv_vLaunchDirection.x, this.kv_vLaunchDirection.y, this.kv_vLaunchDirection.z));
            EEPlateLog('launchtarget: {}'.format(this.kv_sLaunchTarget));
            EEPlateLog('tempStateTime: {}'.format(this.kv_fTempStateTime));
            EEPlateLog('startDisabled: {}'.format(this.kv_bStartDisabled));
            EEPlateLog('launchsound: {}'.format(this.kv_sLaunchSound));
            EEPlateLog("-----------------------------");
        }

        // Add sprite to the face of the faith plate if the model supports it.
        if (this.kv_bAddSprite)
        {
            if (this.LookupAttachment("light") > 0)
            {
                //string offColor = ColorToString(this.kv_vSpriteOffColor);
                //string onColor = ColorToString(this.this.kv_vSpriteOnColor);
                CBaseEntity@ sprite = util::CreateEntityByNameT<CBaseEntity>("env_sprite");
                if (sprite is null)
                {
                    EEPlateLog("Failed to make sprite entity for oee_faithplate with name '{}' and index '{}'!".format(this.GetDebugName(), this.GetEntityIndex()), 1);
                    return;
                }

                sprite.KeyValue("rendercolor", this.kv_bStartDisabled ? ColorToString(this.kv_vSpriteOffColor) : ColorToString(this.kv_vSpriteOnColor));
                sprite.KeyValue("renderamt", this.kv_iSpriteBrightness); // TODO: Could condense this from being a separate KV and instead use the alpha parameter of Color.
                sprite.KeyValue("rendermode", "9");
                sprite.KeyValue("model", "sprites/light_glow02.vmt");
                sprite.KeyValue("scale", "0.7");
                sprite.KeyValue("GlowProxySize", "5");
                sprite.KeyValue("HDRColorScale", "1.0");
                sprite.KeyValue("spawnflags", !this.kv_bStartDisabled);
                sprite.Spawn();
                sprite.Activate();
                sprite.SetParent(this);
                sprite.SetParentAttachment("light");
                this.m_pPlateSprite.Set(sprite);
            }
            else
                EEPlateLog("The oee_faithplate with name '{}' and index '{}' has 'Light Sprite' enabled but model set has no 'light' attachment to use!".format(this.GetDebugName(), this.GetEntityIndex()), 1);
        }

        this.m_bFaithPlateState = !this.kv_bStartDisabled;
        this.SetSkin(RetrieveStateSkin(this.m_bFaithPlateState));
        if (this.m_bFaithPlateState)
            this.m_pTriggerCatapult.Get().Enable();
        else
            this.m_pTriggerCatapult.Get().Disable();

        this.SetThink(ThinkFunc_t(this.MainThink), util::GetCurrentTime(), "CPropFaithPlate::MainThink");
    }


    /**
    * @brief Think function used for both temporary off and on inputs. Makes the plate blink its on and off indicator and emit the sound set ticking.
    */
    void TempStateThink()
    {
        // VERBOSE DEBUG
        // {
        //     EEPlateLog("-------------");
        //     EEPlateLog("goalTempTime: {}".format(this.m_fGoalTempTime));
        //     EEPlateLog("interruptTempState: {}".format(this.m_bInterruptTempState));
        //     EEPlateLog("GetCurrentTime: {}".format(util::GetCurrentTime()));
        //     EEPlateLog("this.goalTempTime <= util::GetCurrentTime(): {}".format(this.m_fGoalTempTime <= util::GetCurrentTime()));
        //     EEPlateLog("-------------");
        // }

        // End state when goal time has passed. Do not exit when goal is negative as that is used for temp states which go on forever.
        if ((this.m_fGoalTempTime <= util::GetCurrentTime()) && kv_fTempStateTime > 0.0f || this.m_bInterruptTempState)
        {
            this.m_fGoalTempTime = 0.0f;

            if (!this.m_bInterruptTempState)
                this.SetEnabled(!this.m_bFaithPlateState);

            this.m_bInterruptTempState = false;
            this.out_onTempExit.Fire(this.m_bFaithPlateState ? 1 : 0, this, this);
            return;
        }

        // Switch between on and off skin states. Blinks every TEMP_STATE_BLINK_INTERVAL seconds.
        bool blinkOn = (int(util::GetCurrentTime() / TEMP_STATE_BLINK_INTERVAL) % 2) == 0;
        if (!blinkOn && this.m_bPreviousBlinkOn)
            this.EmitSound(this.kv_sTickingSound);
        this.m_bPreviousBlinkOn = blinkOn;

        this.SetSkin(this.RetrieveStateSkin(blinkOn));
        if (this.kv_bAddSprite && this.m_pPlateSprite.IsValid())
        {
            if (this.kv_bUseNewDisableSkin)
                this.m_pPlateSprite.Get().KeyValue("renderamt", blinkOn ? this.kv_iSpriteBrightness : "0");
            else
            {
                this.m_pPlateSprite.Get().KeyValue("rendercolor", blinkOn ? ColorToString(this.kv_vSpriteOffColor) : ColorToString(this.kv_vSpriteOnColor));
            }
        }
    }

    void AnimateThink()
    {
        this.StudioFrameAdvance();
        this.DispatchAnimEvents(this);

        if (this.IsSequenceFinished())
            this.ResetSequence(this.m_iAnimFlingIdle);
    }

    void MainThink()
    {
        if (oee_debug_plates.GetBool())
            debug::EntityBounds(this.m_pTriggerCatapult.Get(), 255, 150, 0, 25, 0.05f);

        // Only animate if sequence playback rate is set to play the animation.
        // TODO: Could probably have a better check for this like if a sequence has been set to play instead.
        if (this.GetPlaybackRate() > 0.0f)
            this.AnimateThink();

        if (this.m_fGoalTempTime > 0.0f)
            this.TempStateThink();

        // Msgl("m_aCatapultedObjects.length: {}".format(m_aCatapultedObjects.length()));
        // for (uint i = 0; i < m_aCatapultedObjects.length(); i++)
        // {
        //     EHandle<CBaseEntity> handle = m_aCatapultedObjects[i];

        //     if (!handle.IsValid())
        //     {
        //         m_aCatapultedObjects.removeAt(i);
        //         continue;
        //     }

        //     Msgl("GetDebugName(): {}".format(handle.Get().GetDebugName()));


        //     IPhysicsObject@ pPhys = handle.Get().GetPhysicsObject();
        //     if (pPhys is null)
        //     {
        //         Msgl("IsOnGround: {}".format(handle.Get().IsOnGround()));
        //         if (!handle.Get().IsOnGround())
        //             continue;
        //     }
        //     else
        //     {
        //         //! HACK HACK HACK! This is a temp measure for VPhysics objects to check if they are grounded. REPLACE LATER WHEN ENGINE HAS EXPOSED FUNC!
        //         trace_t groundTrace;
        //         Vector end = this.GetAbsOrigin();
        //         end.z -= this.CollisionProp().GetOBBMaxs().z * 2;
        //         util::TraceLine(this.GetAbsOrigin(), end, util::TraceMask::MASK_SOLID, this, COLLISION_GROUP_NONE, groundTrace);
        //         Msgl("groundTrace.fraction: {}".format(groundTrace.fraction));
        //         if (groundTrace.fraction > 0.51) // 0.51 is about when the object is on the ground.
        //             continue;
        //     }

        //     if (handle.Get().IsPlayer())
        //         handle.Get().StopSound(this.kv_sLaunchMusicTrackPlayer);
        //     else
        //         handle.Get().StopSound(this.kv_sLaunchMusicTrackPhysics);

        //     m_aCatapultedObjects.removeAt(i);
        // }

        SetNextThink(util::GetCurrentTime() + 0.01f, "CPropFaithPlate::MainThink");
    }

// ---------------------------------------------

}

// ---------------------------------------------
