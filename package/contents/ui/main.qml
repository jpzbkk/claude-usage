import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid 2.0

PlasmoidItem {
    id: root

    // ---- Config bindings ----
    property bool showCursor: plasmoid.configuration.showCursor !== false
    property bool showClaude: plasmoid.configuration.showClaude !== false
    property bool showCodex: plasmoid.configuration.showCodex !== false
    property string displayMode: plasmoid.configuration.displayMode || "remaining"
    // ---- Loading / error per provider ----
    property bool cursorLoading: false
    property bool claudeLoading: false
    property bool codexLoading: false
    property string cursorError: ""
    property string claudeError: ""
    property string codexError: ""
    readonly property bool loading: cursorLoading || claudeLoading || codexLoading
    readonly property string errorMessage: {
        var parts = [];
        if (cursorError)
            parts.push("Cursor: " + cursorError);

        if (claudeError)
            parts.push("Claude: " + claudeError);

        if (codexError)
            parts.push("Codex: " + codexError);

        return parts.join(" | ");
    }
    // Cursor data
    property real cursorPlanPercent: 0
    property real cursorOnDemandPercent: 0
    property real cursorUsedUsd: 0
    property real cursorLimitUsd: 0
    property real cursorRemainingUsd: 0
    property real cursorOnDemandUsedUsd: 0
    property var cursorOnDemandLimitUsd: null
    property string cursorMembershipType: ""
    property string cursorBillingCycleEnd: ""
    property bool cursorDataLoaded: false
    // Claude data
    property real claudeSessionPercent: 0
    property real claudeWeeklyPercent: 0
    property string claudeSessionReset: ""
    property string claudeWeeklyReset: ""
    property string claudePlanType: ""
    property var claudeExtraSpend: null
    property var claudeExtraLimit: null
    property bool claudeDataLoaded: false
    // Codex data
    property real codexSessionPercent: 0
    property real codexWeeklyPercent: 0
    property var codexSessionReset: null
    property var codexWeeklyReset: null
    property string codexPlanType: ""
    property var codexCreditsRemaining: null
    property string codexLatestActivity: ""
    property bool codexDataLoaded: false

    // ---- Helper command builder ----
    function buildCmd(provider) {
        var custom = plasmoid.configuration.helperPath;
        if (custom && custom.length > 0)
            return "'" + custom + "' " + provider;

        return "bash -c '\"$HOME/.local/share/token-juice/token-juice-helper\" " + provider + "'";
    }

    // ---- Polling ----
    function fetchAll() {
        if (root.showCursor) {
            root.cursorLoading = true;
            executable.exec(buildCmd("cursor"));
        }
        if (root.showClaude) {
            root.claudeLoading = true;
            executable.exec(buildCmd("claude"));
        }
        if (root.showCodex) {
            root.codexLoading = true;
            executable.exec(buildCmd("codex"));
        }
    }

    function normalizePlanType(value, fallback) {
        if (value === undefined || value === null)
            return fallback;

        var normalized = value.toString().trim();
        if (normalized.length === 0 || normalized === "-")
            return fallback;

        return normalized;
    }

    // Tooltip
    toolTipMainText: "Token Juice"
    toolTipSubText: {
        if (loading)
            return "Loading...";

        var lines = [];
        if (showCursor && cursorDataLoaded) {
            var cp = displayMode === "remaining" ? 100 - cursorPlanPercent : cursorPlanPercent;
            var cd = displayMode === "remaining" ? 100 - cursorOnDemandPercent : cursorOnDemandPercent;
            lines.push("Cursor: P " + cp.toFixed(0) + "% D " + cd.toFixed(0) + "%");
        }
        if (showClaude && claudeDataLoaded) {
            var cs = displayMode === "remaining" ? 100 - claudeSessionPercent : claudeSessionPercent;
            var cw = displayMode === "remaining" ? 100 - claudeWeeklyPercent : claudeWeeklyPercent;
            lines.push("Claude: 5h " + cs.toFixed(0) + "% Wk " + cw.toFixed(0) + "%");
        }
        if (showCodex && codexDataLoaded) {
            var cs = displayMode === "remaining" ? 100 - codexSessionPercent : codexSessionPercent;
            var c7 = displayMode === "remaining" ? 100 - codexWeeklyPercent : codexWeeklyPercent;
            lines.push("Codex: 5h " + cs.toFixed(0) + "% Wk " + c7.toFixed(0) + "%");
        }
        if (errorMessage)
            lines.push(errorMessage);

        return lines.join("\n") || "No providers enabled";
    }
    // Re-fetch when provider toggles change
    onShowCursorChanged: fetchAll()
    onShowClaudeChanged: fetchAll()
    onShowCodexChanged: fetchAll()

    // ---- Executable DataSource ----
    Plasma5Support.DataSource {
        id: executable

        function exec(cmd) {
            executable.connectSource(cmd);
        }

        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            var stdout = data["stdout"];
            if (stdout === undefined || stdout === null)
                return ;

            executable.disconnectSource(source);
            stdout = stdout.toString().trim();
            var stderr = (data["stderr"] || "").toString().trim();
            var exitCode = data["exit code"];
            // Determine which provider this result is for from the command
            var isCursor = source.indexOf("cursor") !== -1;
            var isClaude = source.indexOf("claude") !== -1;
            var isCodex = source.indexOf("codex") !== -1;
            if (isCursor)
                root.cursorLoading = false;

            if (isClaude)
                root.claudeLoading = false;

            if (isCodex)
                root.codexLoading = false;

            if (stdout.length === 0) {
                var errMsg = stderr || ("Helper exited with code " + exitCode);
                if (isCursor)
                    root.cursorError = errMsg;

                if (isClaude)
                    root.claudeError = errMsg;

                if (isCodex)
                    root.codexError = errMsg;

                return ;
            }
            try {
                var result = JSON.parse(stdout);
                if (!result.ok) {
                    if (isCursor)
                        root.cursorError = result.error || "Unknown error";

                    if (isClaude)
                        root.claudeError = result.error || "Unknown error";

                    if (isCodex)
                        root.codexError = result.error || "Unknown error";

                    return ;
                }
                var d = result.data;
                if (result.provider === "cursor") {
                    root.cursorError = "";
                    root.cursorPlanPercent = d.percentUsed || 0;
                    root.cursorOnDemandPercent = d.onDemandPercentUsed || 0;
                    root.cursorUsedUsd = d.usedUsd || 0;
                    root.cursorLimitUsd = d.limitUsd || 0;
                    root.cursorRemainingUsd = d.remainingUsd || 0;
                    root.cursorOnDemandUsedUsd = d.onDemandUsedUsd || 0;
                    root.cursorOnDemandLimitUsd = d.onDemandLimitUsd;
                    root.cursorMembershipType = d.membershipType || "";
                    root.cursorBillingCycleEnd = d.billingCycleEnd || "";
                    root.cursorDataLoaded = true;
                } else if (result.provider === "claude") {
                    root.claudeError = "";
                    root.claudeSessionPercent = d.sessionPercentUsed || 0;
                    root.claudeWeeklyPercent = d.weeklyPercentUsed || 0;
                    root.claudeSessionReset = d.sessionReset || "";
                    root.claudeWeeklyReset = d.weeklyReset || "";
                    root.claudePlanType = root.normalizePlanType(d.planType, "max");
                    root.claudeExtraSpend = d.extraUsageSpend;
                    root.claudeExtraLimit = d.extraUsageLimit;
                    root.claudeDataLoaded = true;
                } else if (result.provider === "codex") {
                    root.codexError = "";
                    root.codexSessionPercent = d.sessionPercentUsed || 0;
                    root.codexWeeklyPercent = d.weeklyPercentUsed || 0;
                    root.codexSessionReset = d.sessionResetEpoch;
                    root.codexWeeklyReset = d.weeklyResetEpoch;
                    root.codexPlanType = root.normalizePlanType(d.planType, "");
                    root.codexCreditsRemaining = d.creditsRemaining;
                    root.codexLatestActivity = d.latestActivity || "";
                    root.codexDataLoaded = true;
                }
            } catch (e) {
                if (isCursor)
                    root.cursorError = "Parse error: " + e.toString();

                if (isClaude)
                    root.claudeError = "Parse error: " + e.toString();

                if (isCodex)
                    root.codexError = "Parse error: " + e.toString();

            }
        }
    }

    Timer {
        id: pollTimer

        interval: (plasmoid.configuration.pollIntervalSeconds || 60) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchAll()
    }

    // ---- Representations ----
    compactRepresentation: CompactRepresentation {
    }

    fullRepresentation: FullRepresentation {
    }

}
