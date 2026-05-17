/**
* @brief   Logger for logging various things. Originally made for ASLib by Enderek.
* @details
* @authors Enderek, Orsell
*
* @license Distributed under the MIT license - Copyright (c) 2026 Project Collapse Studios
*/


class Logger {

    protected string name;
    protected int required_developer_level;
    private ConVar developerCV;

    // Create a logger with a given name, will print out messages as [scriptsys][name]: Message
    // required_developer_level = 0, Message will only print out when the developer ConVar is greater or equal to this value.
    Logger(string name, int required_developer_level = 0) {
        this.name = name;
        this.required_developer_level = required_developer_level;
        this.developerCV = ConVar("developer", "", FCVAR_NONE);
    }

    // Internal method for retrieving developer level
    private int GetDeveloperLevel() {
        return this.developerCV.GetInt();
    }

    // Print an info message to the console
    // string message - the message to print
    // string end - string that gets appended to the end of the message
    // int required_developer_level (optional) - This message will only print out when the developer ConVar is greater or equal to this value. Additionally, any negative value will make it use the global required level passed in the constructor.
    void Info(string message, string end, int required_developer_level = -1) {
        this.__info(message, end, required_developer_level);
    }

    // Print an info message to the console
    // string message - the message to print
    // int required_developer_level - This message will only print out when the developer ConVar is greater or equal to this value. Additionally, any negative value will make it use the global required level passed in the constructor.
    void Info(string message, int required_developer_level) {
        this.__info(message, "\n", required_developer_level);
    }

    // Print an info message to the console
    void Info(string message) {
        this.__info(message, "\n", -1);
    }


    private void __info(string message, string end, int required_developer_level) {
        int dv_lvl = this.GetDeveloperLevel();
        if (
            (required_developer_level > 0 && dv_lvl >= required_developer_level)
            || (required_developer_level < 0 && dv_lvl >= this.required_developer_level)
        ) {
            Msg(message + end);
        }

    }

    // Print an warning message to the console
    // string message - the message to print
    // string end - string that gets appended to the end of the message
    // int required_developer_level (optional) - This message will only print out when the developer ConVar is set to this value. Additionally, any negative value will make it use the global required level passed in the constructor.
    void Warn(string message, string end, int required_developer_level = -1) {
        this.__warn(message, end, required_developer_level);
    }

    // Print an warning message to the console
    // string message - the message to print
    // int required_developer_level - This message will only print out when the developer ConVar is set to this value. Additionally, any negative value will make it use the global required level passed in the constructor.
    void Warn(string message, int required_developer_level) {
        this.__warn(message, "\n", required_developer_level);
    }

    // Print an warning message to the console
    void Warn(string message) {
        this.__warn(message, "\n", -1);
    }


    private void __warn(string message, string end = "\n", int required_developer_level = -1) {
        int dv_lvl = this.GetDeveloperLevel();
        if (
            (required_developer_level > 0 && dv_lvl >= required_developer_level)
            || (required_developer_level < 0 && dv_lvl >= this.required_developer_level)
        ) {
            Warning(message + end);
        }
    }

}