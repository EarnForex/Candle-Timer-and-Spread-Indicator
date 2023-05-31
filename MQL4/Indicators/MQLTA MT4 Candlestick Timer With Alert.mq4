#property link          "https://www.earnforex.com/metatrader-indicators/candle-time-and-spread/"
#property version       "1.02"
#property strict
#property copyright     "EarnForex.com - 2019-2023"
#property description   "Shows details about the instrument, time since last candle, and countdown to next candle."
#property description   "Alert options available."
#property description   " "
#property description   "WARNING: Use this software at your own risk."
#property description   "The creator of these plugins cannot be held responsible for any damage or loss."
#property description   " "
#property description   "Find More on www.EarnForex.com"
#property icon          "\\Files\\EF-Icon-64x64px.ico"

#property indicator_chart_window

#include <MQLTA Utils.mqh>

enum ENUM_PANEL_SIZE
{
    PANEL_SIZE_SMALL = 1,  // SMALL
    PANEL_SIZE_MEDIUM = 2, // MEDIUM
    PANEL_SIZE_LARGE = 3   // LARGE
};

enum ENUM_DEFAULT_OPEN
{
    NOTHING = 0, // NOTHING
    DETAILS = 1, // DETAILS
    CURRENT = 2  // CURRENT
};

enum ENUM_DISPLAY_MODE
{
    MINIMAL = 0, // ONLY COUNTDOWN
    FULL = 1     // FULL INTERFACE
};

enum ENUM_TIMEFORMAT
{
    HMS = 0,   // Hh Mm Ss
    COLON = 1, // HH:MM:SS
};

input string Comment_1 = "====================";    // Candle Timer Settings
input string IndicatorName = "CNDLTMR";             // Indicator Name (used to draw objects)
input ENUM_DISPLAY_MODE DefaultDisplay = MINIMAL;   // Interface
input ENUM_DEFAULT_OPEN DefaultOpen = CURRENT;      // Default Window Open
input ENUM_TIMEFORMAT TimeFormat = HMS;             // Time Format
input string Comment_2 = "====================";    // Notification Options
input bool EnableNotify = false;                    // Enable Notifications Feature
input int SecondsNotice = 60;                       // Seconds Of Notice For Alert
input bool SendAlert = true;                        // Send Alert Notification
input bool SendApp = false;                         // Send Notification to Mobile
input bool SendEmail = false;                       // Send Notification via Email
input string Comment_3 = "====================";    // Panel Position
input ENUM_BASE_CORNER Corner = CORNER_LEFT_UPPER;  // Panel Chart Corner
input int Xoff = 20;                                // Horizontal spacing for the control panel
input int Yoff = 20;                                // Vertical spacing for the control panel
input int FontSize = 8;                             // Font Size
input ENUM_PANEL_SIZE PanelSize = PANEL_SIZE_SMALL; // Panel Size
input string Comment_4 = "====================";    // Panel Colors
input color LargeFontColor = clrNavy;               // Large Font Color
input color SmallFontColor = clrBlack;              // Small Font Color
input color CaptionBGColor = clrKhaki;              // Caption Background Color
input color EditsBGColor = clrWhiteSmoke;           // Edits Background Color
input color BorderColor = clrBlack;                 // Border Color
input color BorderFillColor = clrWhite;             // Border Fill Color

int CornerSignX = 1;
int CornerSignY = 1;

string HoursString = "";
string MinutesString = "";
string SecondsString = "";

string Font = "Consolas";

bool DetailsOpen = false;
bool CurrentOpen = false;
bool NotifiedThisCandle = false;

double DPIScale; // Scaling parameter for the panel based on the screen DPI.
int PanelMovX, PanelMovY, PanelLabX, PanelLabY, PanelRecX;
int DetGLabelX, DetGLabelEX, DetGLabelY, DetButtonX, DetButtonY;
int CurGLabelX, CurGLabelEX, CurGLabelY, CurButtonX, CurButtonY;

int OnInit()
{
    IndicatorSetString(INDICATOR_SHORTNAME, IndicatorName);
    
    CleanChart();
    
    if (Corner == CORNER_LEFT_UPPER)
    {
        CornerSignX = 1;
        CornerSignY = 1;
    }
    else if (Corner == CORNER_LEFT_LOWER)
    {
        CornerSignX = 1;
        CornerSignY = -1;
    }
    else if (Corner == CORNER_RIGHT_UPPER)
    {
        CornerSignX = -1;
        CornerSignY = 1;
    }
    else if (Corner == CORNER_RIGHT_LOWER)
    {
        CornerSignX = -1;
        CornerSignY = -1;
    }

    DPIScale = (double)TerminalInfoInteger(TERMINAL_SCREEN_DPI) / 96.0;

    PanelMovX = (int)MathRound(26 * DPIScale * PanelSize);
    PanelMovY = (int)MathRound(26 * DPIScale * PanelSize);
    PanelLabX = (int)MathRound(120 * DPIScale * PanelSize);
    PanelLabY = PanelMovY;
    PanelRecX = (PanelMovX + 2) * 2 + PanelLabX + 2;

    DetGLabelX = (int)MathRound(80 * DPIScale * PanelSize);
    DetGLabelEX = (int)MathRound(80 * DPIScale * PanelSize);
    DetGLabelY = (int)MathRound(20 * DPIScale * PanelSize);
    DetButtonX = (int)MathRound(90 * DPIScale * PanelSize);
    DetButtonY = DetGLabelY;

    CurGLabelX = (int)MathRound(80 * DPIScale * PanelSize);
    CurGLabelEX = (int)MathRound(80 * DPIScale * PanelSize);
    CurGLabelY = (int)MathRound(20 * DPIScale * PanelSize);
    CurButtonX = (int)MathRound(90 * DPIScale * PanelSize);
    CurButtonY = DetGLabelY;

    if (TimeFormat == HMS)
    {
        HoursString = "h ";
        MinutesString = "m ";
        SecondsString = "s";
    }
    else if (TimeFormat == COLON)
    {
        HoursString = ":";
        MinutesString = ":";
        SecondsString = "";
    }

    if ((DefaultDisplay == 1) && (DefaultOpen == 1)) DetailsOpen = true;
    if ((DefaultDisplay == 1) && (DefaultOpen == 2)) CurrentOpen = true;
    if (DefaultDisplay == 1) CreateMiniPanel();
    if (DefaultDisplay == 0) ShowCountdown();
    if (DefaultDisplay == 0)
    {
        DetailsOpen = false;
        CurrentOpen = false;
    }

    EventSetTimer(1);
    
    return INIT_SUCCEEDED;
}

void OnTimer()
{
    if (IsNewCandle()) NotifiedThisCandle = false;
    if (DetailsOpen) ShowDetails();
    if (CurrentOpen) ShowCurrent();
    if (DefaultDisplay == 0) ShowCountdown();
    if (EnableNotify) NotifyCountdown();
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    if (IsNewCandle()) NotifiedThisCandle = false;
    if (DetailsOpen) ShowDetails();
    if (CurrentOpen) ShowCurrent();
    if (DefaultDisplay == 0) ShowCountdown();
    if (EnableNotify) NotifyCountdown();

    return rates_total;
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        if (sparam == PanelDet)
        {
            if (DetailsOpen) CloseDetails();
            else ShowDetails();
        }
        else if (sparam == PanelCur)
        {
            if (CurrentOpen) CloseCurrent();
            else ShowCurrent();
        }
    }
}

void OnDeinit(const int reason)
{
    CleanChart();
    EventKillTimer();
}

datetime NewCandleTime = TimeCurrent();
bool IsNewCandle()
{
    if (NewCandleTime == iTime(Symbol(), 0, 0)) return false;
    else
    {
        NewCandleTime = iTime(Symbol(), 0, 0);
        return true;
    }
}

void NotifyCountdown()
{
    if (NotifiedThisCandle) return;

    long SecondsRemaining = 0;
    SecondsRemaining = (long)(Time[0] + PeriodSeconds(PERIOD_CURRENT) - TimeCurrent());
    if (SecondsRemaining > SecondsNotice) return;

    if ((!SendAlert) && (!SendApp) && (!SendEmail)) return;

    string EmailSubject = IndicatorName + " " + Symbol() + " Notification";
    string EmailBody = AccountCompany() + " - " + AccountName() + " - " + IntegerToString(AccountNumber()) + "\r\n" + IndicatorName + " Notification for " + Symbol();
    EmailBody += "\r\nNext candle forming in less than " + (string)SecondsRemaining + " seconds";
    string AlertText = IndicatorName + " - " + Symbol() + ": Next candle forming in less than " + (string)SecondsRemaining + " seconds.";
    string AppText = AccountCompany() + " - " + AccountName() + " - " + IntegerToString(AccountNumber()) + " - " + IndicatorName + " - " + Symbol() + " - ";
    AppText += "less than " + (string)SecondsRemaining + " seconds to next candle.";
    if (SendAlert) Alert(AlertText);
    if (SendEmail)
    {
        if (!SendMail(EmailSubject, EmailBody)) Print("Error sending email " + IntegerToString(GetLastError()));
    }
    if (SendApp)
    {
        if (!SendNotification(AppText)) Print("Error sending notification " + IntegerToString(GetLastError()));
    }
    NotifiedThisCandle = true;
}

void CleanChart()
{
    ObjectsDeleteAll(0, IndicatorName);
}

void CleanMiniPanel()
{
    ObjectsDeleteAll(0, IndicatorName + "-P-");
}

string PanelBase = IndicatorName + "-P-BAS";
string PanelLabel = IndicatorName + "-P-LAB";
string PanelDet = IndicatorName + "-P-DET";
string PanelCur = IndicatorName + "-P-CUR";
void CreateMiniPanel()
{
    CleanMiniPanel();
    ObjectCreate(0, PanelBase, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, PanelBase, OBJPROP_XDISTANCE, Xoff);
    ObjectSetInteger(0, PanelBase, OBJPROP_YDISTANCE, Yoff);
    ObjectSetInteger(0, PanelBase, OBJPROP_XSIZE, PanelRecX);
    ObjectSetInteger(0, PanelBase, OBJPROP_YSIZE, (PanelMovY + 2) * 1 + 2);
    ObjectSetInteger(0, PanelBase, OBJPROP_BGCOLOR, BorderFillColor);
    ObjectSetInteger(0, PanelBase, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, PanelBase, OBJPROP_STATE, false);
    ObjectSetInteger(0, PanelBase, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, PanelBase, OBJPROP_FONTSIZE, FontSize);
    ObjectSetInteger(0, PanelBase, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, PanelBase, OBJPROP_COLOR, BorderColor);
    ObjectSetInteger(0, PanelBase, OBJPROP_CORNER, Corner);
    
    DrawEdit(PanelLabel, Xoff + CornerSignX * 2, Yoff + CornerSignY * 2, PanelLabX, PanelLabY, true, FontSize + 4, "CANDLE TIMER", ALIGN_CENTER, "Consolas", "CANDLE TIMER", false, LargeFontColor, CaptionBGColor, BorderColor);
    ObjectSetInteger(0, PanelLabel, OBJPROP_CORNER, Corner);
    DrawEdit(PanelDet, Xoff + CornerSignX * (PanelLabX + 3), Yoff + CornerSignY * 2, PanelMovX, PanelMovX, true, FontSize + 4, "Click to open/close the details", ALIGN_CENTER, "Wingdings", "3", false, LargeFontColor, CaptionBGColor, BorderColor);
    ObjectSetInteger(0, PanelDet, OBJPROP_CORNER, Corner);
    DrawEdit(PanelCur, Xoff + CornerSignX * (PanelLabX + PanelMovX + 1 + 3), Yoff + CornerSignY * 2, PanelMovX, PanelMovX, true, FontSize + 4, "Click to open/close timer", ALIGN_CENTER, "Wingdings", "Â", false, LargeFontColor, CaptionBGColor, BorderColor);
    ObjectSetInteger(0, PanelCur, OBJPROP_CORNER, Corner);
}

string DetailsBase = IndicatorName + "-D-Base";
string DetailsSave = IndicatorName + "-D-Save";
string DetailsClose = IndicatorName + "-D-Close";
string DetailsDescription = IndicatorName + "-D-Description";
string DetailsDescriptionE = IndicatorName + "-D-DescriptionE";
string DetailsTrade = IndicatorName + "-D-Trade";
string DetailsTradeE = IndicatorName + "-D-TradeE";
string DetailsContractSize = IndicatorName + "-D-ContractSize";
string DetailsContractSizeE = IndicatorName + "-D-ContractSizeE";
string DetailsMinLot = IndicatorName + "-D-MinLot";
string DetailsMinLotE = IndicatorName + "-D-MinLotE";
string DetailsMaxLot = IndicatorName + "-D-MaxLot";
string DetailsMaxLotE = IndicatorName + "-D-MaxLotE";
string DetailsLotStep = IndicatorName + "-D-LotStep";
string DetailsLotStepE = IndicatorName + "-D-LotStepE";
string DetailsDigits = IndicatorName + "-D-Digits";
string DetailsDigitsE = IndicatorName + "-D-DigitsE";
string DetailsTickSize = IndicatorName + "-D-TickSize";
string DetailsTickSizeE = IndicatorName + "-D-TickSizeE";
string DetailsTickValue = IndicatorName + "-D-TickValue";
string DetailsTickValueE = IndicatorName + "-D-TickValueE";
string DetailsStopLevel = IndicatorName + "-D-StopLevel";
string DetailsStopLevelE = IndicatorName + "-D-StopLevelE";
void ShowDetails()
{
    CloseDetails();
    CloseCurrent();
    int DetXoff = Xoff;
    int DetYoff = Yoff + CornerSignY * (PanelMovY * 1 + 6);
    int DetX = DetGLabelX + DetGLabelEX + 6;
    int DetY = (DetButtonY + 2) * 7 + 2;
    int j = 0;

    long TradeDescription = 0;

    string TextDescription;
    string TextTrade = "";
    string TextContractSize = "";
    string TextMinLot = "";
    string TextMaxLot = "";
    string TextLotStep = "";
    string TextDigits = "";
    string TextStopLevel = "";
    string TextTickSize = "";
    string TextTickValue = "";

    TextDescription = Symbol();
    TradeDescription = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE);
    if (TradeDescription == SYMBOL_TRADE_MODE_DISABLED) TextTrade = "DISABLED";
    if (TradeDescription == SYMBOL_TRADE_MODE_LONGONLY) TextTrade = "BUY ONLY";
    if (TradeDescription == SYMBOL_TRADE_MODE_SHORTONLY) TextTrade = "SELL ONLY";
    if (TradeDescription == SYMBOL_TRADE_MODE_CLOSEONLY) TextTrade = "CLOSE ONLY";
    if (TradeDescription == SYMBOL_TRADE_MODE_FULL) TextTrade = "FULL";

    TextContractSize = (string)MarketInfo(Symbol(), MODE_LOTSIZE);
    TextMinLot = (string)MarketInfo(Symbol(), MODE_MINLOT);
    TextMaxLot = (string)MarketInfo(Symbol(), MODE_MAXLOT);
    TextLotStep = (string)MarketInfo(Symbol(), MODE_LOTSTEP);
    TextDigits = (string)MarketInfo(Symbol(), MODE_DIGITS);
    TextStopLevel = (string)MarketInfo(Symbol(), MODE_STOPLEVEL);
    TextTickSize = (string)DoubleToStr(MarketInfo(Symbol(), MODE_TICKSIZE), Digits);
    TextTickValue = DoubleToStr(MarketInfo(Symbol(), MODE_TICKVALUE), 2) + " " + AccountCurrency();

    ObjectCreate(0, DetailsBase, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSet(DetailsBase, OBJPROP_XDISTANCE, DetXoff);
    ObjectSet(DetailsBase, OBJPROP_YDISTANCE, DetYoff);
    ObjectSetInteger(0, DetailsBase, OBJPROP_XSIZE, DetX);
    ObjectSetInteger(0, DetailsBase, OBJPROP_YSIZE, DetY);
    ObjectSetInteger(0, DetailsBase, OBJPROP_BGCOLOR, BorderFillColor);
    ObjectSetInteger(0, DetailsBase, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, DetailsBase, OBJPROP_STATE, false);
    ObjectSetInteger(0, DetailsBase, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, DetailsBase, OBJPROP_FONTSIZE, FontSize);
    ObjectSet(DetailsBase, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, DetailsBase, OBJPROP_COLOR, BorderColor);
    ObjectSetInteger(0, DetailsBase, OBJPROP_CORNER, Corner);

    DrawEdit(DetailsDescription, DetXoff + CornerSignX * 2, DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelX, DetGLabelY, true, FontSize, "Instrument Label", ALIGN_LEFT, Font, "Instrument", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsDescription, OBJPROP_CORNER, Corner);
    DrawEdit(DetailsDescriptionE, DetXoff + CornerSignX * (2 + DetGLabelX + 2), DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelEX, DetButtonY, true, FontSize, "Instrument Label", ALIGN_CENTER, Font, TextDescription, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsDescriptionE, OBJPROP_CORNER, Corner);
    j++;

    DrawEdit(DetailsTrade, DetXoff + CornerSignX * 2, DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelX, DetGLabelY, true, FontSize, "Trade Status", ALIGN_LEFT, Font, "Trade", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsTrade, OBJPROP_CORNER, Corner);
    DrawEdit(DetailsTradeE, DetXoff + CornerSignX * (2 + DetGLabelX + 2), DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelEX, DetButtonY, true, FontSize, "Trade Status", ALIGN_CENTER, Font, TextTrade, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsTradeE, OBJPROP_CORNER, Corner);
    j++;

    DrawEdit(DetailsContractSize, DetXoff + CornerSignX * 2, DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelX, DetGLabelY, true, FontSize, "Contract Size For Standard Lot", ALIGN_LEFT, Font, "Contract", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsContractSize, OBJPROP_CORNER, Corner);
    DrawEdit(DetailsContractSizeE, DetXoff + CornerSignX * (2 + DetGLabelX + 2), DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelEX, DetButtonY, true, FontSize, "Contract Size For Standard Lot", ALIGN_CENTER, Font, TextContractSize, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsContractSizeE, OBJPROP_CORNER, Corner);
    j++;

    DrawEdit(DetailsMinLot, DetXoff + CornerSignX * 2, DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelX, DetGLabelY, true, FontSize, "Minimum Lot Size", ALIGN_LEFT, Font, "Min Lot", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsMinLot, OBJPROP_CORNER, Corner);
    DrawEdit(DetailsMinLotE, DetXoff + CornerSignX * (2 + DetGLabelX + 2), DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelEX, DetButtonY, true, FontSize, "Minimum Lot Size", ALIGN_CENTER, Font, TextMinLot, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsMinLotE, OBJPROP_CORNER, Corner);
    j++;

    DrawEdit(DetailsMaxLot, DetXoff + CornerSignX * 2, DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelX, DetGLabelY, true, FontSize, "Maximum Lot Size", ALIGN_LEFT, Font, "Max Lot", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsMaxLot, OBJPROP_CORNER, Corner);
    DrawEdit(DetailsMaxLotE, DetXoff + CornerSignX * (2 + DetGLabelX + 2), DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelEX, DetButtonY, true, FontSize, "Maximum Lot Size", ALIGN_CENTER, Font, TextMaxLot, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsMaxLotE, OBJPROP_CORNER, Corner);
    j++;

    DrawEdit(DetailsLotStep, DetXoff + CornerSignX * 2, DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelX, DetGLabelY, true, FontSize, "Lot Increment", ALIGN_LEFT, Font, "Lot Step", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsLotStep, OBJPROP_CORNER, Corner);
    DrawEdit(DetailsLotStepE, DetXoff + CornerSignX * (2 + DetGLabelX + 2), DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelEX, DetButtonY, true, FontSize, "Lot Increment", ALIGN_CENTER, Font, TextLotStep, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsLotStepE, OBJPROP_CORNER, Corner);
    j++;

    DrawEdit(DetailsDigits, DetXoff + CornerSignX * 2, DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelX, DetGLabelY, true, FontSize, "Instrument Digits", ALIGN_LEFT, Font, "Digits", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsDigits, OBJPROP_CORNER, Corner);
    DrawEdit(DetailsDigitsE, DetXoff + CornerSignX * (2 + DetGLabelX + 2), DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelEX, DetButtonY, true, FontSize, "Instrument Digits", ALIGN_CENTER, Font, TextDigits, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsDigitsE, OBJPROP_CORNER, Corner);
    j++;

    DrawEdit(DetailsTickSize, DetXoff + CornerSignX * 2, DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelX, DetGLabelY, true, FontSize, "Tick Size", ALIGN_LEFT, Font, "Tick Size", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsTickSize, OBJPROP_CORNER, Corner);
    DrawEdit(DetailsTickSizeE, DetXoff + CornerSignX * (2 + DetGLabelX + 2), DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelEX, DetButtonY, true, FontSize, "Tick Size", ALIGN_CENTER, Font, TextTickSize, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsTickSizeE, OBJPROP_CORNER, Corner);
    j++;

    DrawEdit(DetailsTickValue, DetXoff + CornerSignX * 2, DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelX, DetGLabelY, true, FontSize, "Tick Value Per Standard Lot", ALIGN_LEFT, Font, "Tick Value", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsTickValue, OBJPROP_CORNER, Corner);
    DrawEdit(DetailsTickValueE, DetXoff + CornerSignX * (2 + DetGLabelX + 2), DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelEX, DetButtonY, true, FontSize, "Tick Value Per Standard Lot", ALIGN_CENTER, Font, TextTickValue, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsTickValueE, OBJPROP_CORNER, Corner);
    j++;

    DrawEdit(DetailsStopLevel, DetXoff + CornerSignX * 2, DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelX, DetGLabelY, true, FontSize, "Stop Level", ALIGN_LEFT, Font, "Stop Level", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsStopLevel, OBJPROP_CORNER, Corner);
    DrawEdit(DetailsStopLevelE, DetXoff + CornerSignX * (2 + DetGLabelX + 2), DetYoff + CornerSignY * (2 + (DetButtonY + 2) * j), DetGLabelEX, DetButtonY, true, FontSize, "Stop Level", ALIGN_CENTER, Font, TextStopLevel, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, DetailsStopLevelE, OBJPROP_CORNER, Corner);
    j++;

    DetY = (DetButtonY + 2) * j + 2;
    ObjectSetInteger(0, DetailsBase, OBJPROP_YSIZE, DetY);

    DetailsOpen = true;
}

void CloseDetails()
{
    ObjectsDeleteAll(0, IndicatorName + "-D-");
    DetailsOpen = false;
}

string CurrentBase = IndicatorName + "-C-Base";
string CurrentBid = IndicatorName + "-C-Bid";
string CurrentBidE = IndicatorName + "-C-BidE";
string CurrentSpread = IndicatorName + "-C-Spread";
string CurrentSpreadE = IndicatorName + "-C-SpreadE";
string CurrentAsk = IndicatorName + "-C-Ask";
string CurrentAskE = IndicatorName + "-C-AskE";
string CurrentTimeElapsed = IndicatorName + "-C-Elapsed";
string CurrentTimeElapsedE = IndicatorName + "-C-ElapsedE";
string CurrentTimeRemaining = IndicatorName + "-C-Remaining";
string CurrentTimeRemainingE = IndicatorName + "-C-RemainingE";
void ShowCurrent()
{
    CloseDetails();
    CloseCurrent();
    int CurXoff = Xoff;
    int CurYoff = Yoff + CornerSignY * (PanelMovY * 1 + 6);
    int CurX = CurGLabelX + CurGLabelEX + 6;
    int CurY = (CurButtonY + 2) * 7 + 2;
    int j = 0;

    string TextBid = "";
    string TextSpread = "";
    string TextAsk = "";
    string TextElapsed = "";
    string TextRemaining = "";

    TextBid = DoubleToStr(NormalizeDouble(MarketInfo(Symbol(), MODE_BID), Digits), Digits);
    TextSpread = DoubleToStr(NormalizeDouble(MarketInfo(Symbol(), MODE_SPREAD) * MarketInfo(Symbol(), MODE_POINT), Digits), Digits);
    TextAsk = DoubleToStr(NormalizeDouble(MarketInfo(Symbol(), MODE_ASK), Digits), Digits);

    long SecondsElapsed = 0;
    int HourElapsed = 0;
    int MinutesElapsed = 0;

    SecondsElapsed = (long)(TimeCurrent() - Time[0]);
    HourElapsed = (int)MathFloor(SecondsElapsed / 3600);
    SecondsElapsed = SecondsElapsed - HourElapsed * 3600;
    MinutesElapsed = (int)MathFloor(SecondsElapsed / 60);
    SecondsElapsed = SecondsElapsed - MinutesElapsed * 60;

    if (HourElapsed > 0) TextElapsed += Format(IntegerToString(HourElapsed)) + HoursString;
    if (MinutesElapsed > 0) TextElapsed += Format(IntegerToString(MinutesElapsed)) + MinutesString;
    TextElapsed += Format(IntegerToString(SecondsElapsed)) + SecondsString;

    long SecondsRemaining = 0;
    int HourRemaining = 0;
    int MinutesRemaining = 0;

    SecondsRemaining = (long)(Time[0] + PeriodSeconds(PERIOD_CURRENT) - TimeCurrent());
    HourRemaining = (int)MathFloor(SecondsRemaining / 3600);
    SecondsRemaining = SecondsRemaining - HourRemaining * 3600;
    MinutesRemaining = (int)MathFloor(SecondsRemaining / 60);
    SecondsRemaining = SecondsRemaining - MinutesRemaining * 60;

    if (HourRemaining > 0) TextRemaining += Format(IntegerToString(HourRemaining)) + HoursString;
    if (MinutesRemaining > 0) TextRemaining += Format(IntegerToString(MinutesRemaining)) + MinutesString;
    TextRemaining += Format(IntegerToString(SecondsRemaining)) + SecondsString;

    ObjectCreate(0, CurrentBase, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSet(CurrentBase, OBJPROP_XDISTANCE, CurXoff);
    ObjectSet(CurrentBase, OBJPROP_YDISTANCE, CurYoff);
    ObjectSetInteger(0, CurrentBase, OBJPROP_XSIZE, CurX);
    ObjectSetInteger(0, CurrentBase, OBJPROP_YSIZE, CurY);
    ObjectSetInteger(0, CurrentBase, OBJPROP_BGCOLOR, BorderFillColor);
    ObjectSetInteger(0, CurrentBase, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, CurrentBase, OBJPROP_STATE, false);
    ObjectSetInteger(0, CurrentBase, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, CurrentBase, OBJPROP_FONTSIZE, FontSize);
    ObjectSet(CurrentBase, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, CurrentBase, OBJPROP_COLOR, BorderColor);
    ObjectSetInteger(0, CurrentBase, OBJPROP_CORNER, Corner);

    DrawEdit(CurrentBid, CurXoff + CornerSignX * 2, CurYoff + CornerSignY * (2 + (CurButtonY + 2) * j), CurGLabelX, CurGLabelY, true, FontSize, "Current Bid/Sell Price", ALIGN_LEFT, Font, "Bid", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, CurrentBid, OBJPROP_CORNER, Corner);
    DrawEdit(CurrentBidE, CurXoff + CornerSignX * (2 + CurGLabelX + 2), CurYoff + CornerSignY * (2 + (CurButtonY + 2) * j), CurGLabelEX, CurButtonY, true, FontSize, "Current Bid/Sell Price", ALIGN_CENTER, Font, TextBid, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, CurrentBidE, OBJPROP_CORNER, Corner);
    j++;

    DrawEdit(CurrentSpread, CurXoff + CornerSignX * 2, CurYoff + CornerSignY * (2 + (CurButtonY + 2) * j), CurGLabelX, CurGLabelY, true, FontSize, "Current Spread", ALIGN_LEFT, Font, "Spread", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, CurrentSpread, OBJPROP_CORNER, Corner);
    DrawEdit(CurrentSpreadE, CurXoff + CornerSignX * (2 + CurGLabelX + 2), CurYoff + CornerSignY * (2 + (CurButtonY + 2) * j), CurGLabelEX, CurButtonY, true, FontSize, "Current Spread", ALIGN_CENTER, Font, TextSpread, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, CurrentSpreadE, OBJPROP_CORNER, Corner);
    j++;

    DrawEdit(CurrentAsk, CurXoff + CornerSignX * 2, CurYoff + CornerSignY * (2 + (CurButtonY + 2) * j), CurGLabelX, CurGLabelY, true, FontSize, "Current Ask/Buy Price", ALIGN_LEFT, Font, "Ask", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, CurrentAsk, OBJPROP_CORNER, Corner);
    DrawEdit(CurrentAskE, CurXoff + CornerSignX * (2 + CurGLabelX + 2), CurYoff + CornerSignY * (2 + (CurButtonY + 2) * j), CurGLabelEX, CurButtonY, true, FontSize, "Current Ask/Buy Price", ALIGN_CENTER, Font, TextAsk, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, CurrentAskE, OBJPROP_CORNER, Corner);
    j++;

    DrawEdit(CurrentTimeElapsed, CurXoff + CornerSignX * 2, CurYoff + CornerSignY * (2 + (CurButtonY + 2) * j), CurGLabelX, CurGLabelY, true, FontSize, "Time Since Candle Start", ALIGN_LEFT, Font, "Elapsed", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, CurrentTimeElapsed, OBJPROP_CORNER, Corner);
    DrawEdit(CurrentTimeElapsedE, CurXoff + CornerSignX * (2 + CurGLabelX + 2), CurYoff + CornerSignY * (2 + (CurButtonY + 2) * j), CurGLabelEX, CurButtonY, true, FontSize, "Time Since Candle Start", ALIGN_CENTER, Font, TextElapsed, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, CurrentTimeElapsedE, OBJPROP_CORNER, Corner);
    j++;

    DrawEdit(CurrentTimeRemaining, CurXoff + CornerSignX * 2, CurYoff + CornerSignY * (2 + (CurButtonY + 2) * j), CurGLabelX, CurGLabelY, true, FontSize, "Time To Next Candle", ALIGN_LEFT, Font, "Remaining", false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, CurrentTimeRemaining, OBJPROP_CORNER, Corner);
    DrawEdit(CurrentTimeRemainingE, CurXoff + CornerSignX * (2 + CurGLabelX + 2), CurYoff + CornerSignY * (2 + (CurButtonY + 2) * j), CurGLabelEX, CurButtonY, true, FontSize, "Time To Next Candle", ALIGN_CENTER, Font, TextRemaining, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, CurrentTimeRemainingE, OBJPROP_CORNER, Corner);
    j++;

    CurY = (CurButtonY + 2) * j + 2;
    ObjectSetInteger(0, CurrentBase, OBJPROP_YSIZE, CurY);

    CurrentOpen = true;
}

void ShowCountdown()
{
    CloseCurrent();
    int CurXoff = Xoff;
    int CurYoff = Yoff;
    int CurX = CurGLabelX + CurGLabelEX + 6;
    int CurY = (CurButtonY + 2) * 7 + 2;
    int j = 0;

    string TextRemaining = "";

    long SecondsRemaining = 0;
    int HourRemaining = 0;
    int MinutesRemaining = 0;

    SecondsRemaining = (long)(iTime(Symbol(), PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT) - TimeCurrent());
    HourRemaining = (int)MathFloor(SecondsRemaining / 3600);
    SecondsRemaining = SecondsRemaining - HourRemaining * 3600;
    MinutesRemaining = (int)MathFloor(SecondsRemaining / 60);
    SecondsRemaining = SecondsRemaining - MinutesRemaining * 60;

    if (HourRemaining > 0) TextRemaining += Format(IntegerToString(HourRemaining)) + HoursString;
    if (MinutesRemaining > 0) TextRemaining += Format(IntegerToString(MinutesRemaining)) + MinutesString;
    TextRemaining += Format(IntegerToString(SecondsRemaining)) + SecondsString;

    DrawEdit(CurrentTimeRemainingE, CurXoff, CurYoff + CornerSignY * (2 + (CurButtonY + 2) * j), CurGLabelEX, CurButtonY, true, FontSize, "Time To Next Candle", ALIGN_CENTER, Font, TextRemaining, false, SmallFontColor, EditsBGColor, BorderColor);
    ObjectSetInteger(0, CurrentTimeRemainingE, OBJPROP_CORNER, Corner);
    j++;
}

void CloseCurrent()
{
    ObjectsDeleteAll(0, IndicatorName + "-C-");
    CurrentOpen = false;
}

// Format string for time by adding zero in front of it if its length less than two.
string Format(string s)
{
    if (TimeFormat == HMS) return s; // No leading zero.
    if (StringLen(s) < 2) return "0" + s;
    return s;
}
//+------------------------------------------------------------------+