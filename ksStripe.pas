unit ksStripe;

interface

uses Classes, Json, Generics.Collections;

type
  TStripeCurrency = (scGbp, scUsd);

  IStripeBaseObject = interface
  ['{AC396FFE-A89C-4811-8DDD-5A3A69546155}']
    function GetID: string;
    function GetObject: string;
    procedure LoadFromJson(AJson: TJsonObject);
    property ID: string read GetID;
    property Obj: string read GetObject;
  end;

  IStripeBaseObjectList = interface
  ['{3FD36F72-3FF3-4377-AE0E-120A19C63354}']
    function GetItem(index: integer): IStripeBaseObject;
    function GetListID: string;
    procedure Clear;
    procedure LoadFromJson(AJson: TJSONObject);
    property Item[index: integer]: IStripeBaseObject read GetItem;
  end;

  IStripePlan = interface(IStripeBaseObject)
  ['{E37D8D42-0FDE-4108-BD58-56603955FDCC}']
    function GetAmountPence: integer;
    function GetCreated: TDateTime;
    function GetCurrency: string;
    function GetInterval: string;
    function GetIntervalCount: integer;
    function GetName: string;
    function GetStatementDescriptor: string;
    function GetTrialPeriodDays: integer;
    property Interval: string read GetInterval;
    property Name: string read GetName;
    property Created: TDateTime read GetCreated;
    property AmountPence: integer read GetAmountPence;
    property Currency: string read GetCurrency;
    property IntervalCount: integer read GetIntervalCount;
    property TrialPeriodDays: integer read GetTrialPeriodDays;
    property StatementDescriptor: string read GetStatementDescriptor;
  end;

  IStripeSubscription = interface(IStripeBaseObject)
  ['{3F2BE016-7483-4020-BEB6-F0A3B55E9753}']
    function GetCancelledAt: TDateTime;
    function GetCurrentPeriodEnd: TDateTime;
    function GetCurrentPeriodStart: TDateTime;
    function GetCustomer: string;
    function GetEndedAt: TDateTime;
    function GetPlan: IStripePlan;
    function GetQuantity: integer;
    function GetStart: TDateTime;
    function GetStatus: string;
    function GetTaxPercent: single;
    function GetTrialEnd: TDateTime;
    function GetTrialStart: TDateTime;
    property Plan: IStripePlan read GetPlan;
    property Start: TDateTime read GetStart;
    property Status: string read GetStatus;
    property Customer: string read GetCustomer;
    property CurrentPeriodStart: TDateTime read GetCurrentPeriodStart;
    property CurrentPeriodEnd: TDateTime read GetCurrentPeriodEnd;
    property EndedAt: TDateTime read GetEndedAt;
    property TrialStart: TDateTime read GetTrialStart;
    property TrialEnd: TDateTime read GetTrialEnd;
    property CancelledAt: TDateTime read GetCancelledAt;
    property Quantity: integer read GetQuantity;
    property TaxPercent: single read GetTaxPercent;
  end;

  IStripeSubscriptionList = interface(IStripeBaseObjectList)
  ['{27861C97-3F5F-4546-9CAE-1248040E5159}']
  end;


  IStripeCustomer = interface(IStripeBaseObject)
  ['{CFA07B51-F63C-4972-ACAB-FA51D6DF5779}']
    function GetAccountBalance: integer;
    function GetCurrency: string;
    function GetEmail: string;
    property Email: string read GetEmail;
    property Currency: string read GetCurrency;
    property AccountBalance: integer read GetAccountBalance;
  end;

  IStripeCusotomerList = interface(IStripeBaseObjectList)
  ['{A84D8E11-C142-4E4C-9698-A6DFBCE14742}']
  end;

  IStripeCard = interface(IStripeBaseObject)
  ['{76652D56-42CE-4C2F-B0B2-1E6485D501AD}']
    function GetBrand: string;
    function GetFunding: string;
    function GetLast4: string;
    function GetAddress1: string;
    function GetCountry: string;
    function GetExpMonth: integer;
    function GetExpYear: integer;
    function GetName: string;
    function GetAddress2: string;
    function GetCity: string;
    function GetState: string;
    function GetZip: string;
    function GetAddressCountry: string;
    function GetCvcCheck: string;
    property Last4: string read GetLast4;
    property Brand: string read GetBrand;
    property Funding: string read GetFunding;
    property ExpMonth: integer read GetExpMonth;
    property ExpYear: integer read GetExpYear;
    property Country: string read GetCountry;
    property Name: string read GetName;
    property Address1: string read GetAddress1;
    property Address2: string read GetAddress2;
    property City: string read GetCity;
    property State: string read GetState;
    property Zip: string read GetZip;
    property AddressCountry: string read GetAddressCountry;
    property CvcCheck: string read GetCvcCheck;
  end;

  IStripe = interface
  ['{A00E2188-0DDB-469F-9C4A-0900DEEFD27B}']
    function GetCustomer(ACustID: string): IStripeCustomer;
    function CreateToken(ACardNum: string; AExpMonth, AExpYear: integer; ACvc: string): string;
    procedure CreateCharge(AToken, ADescription: string; AAmountPence: integer; const ACurrency: TStripeCurrency = scGbp);
  end;

  function  CreateStripe(ASecretKey: string): IStripe;

implementation

uses System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent,
  SysUtils, DateUtils;

const
  C_CARD = 'card';
  C_CARDS = 'cards';
  C_CHARGE = 'charge';
  C_CHARGES = 'charges';
  C_CUSTOMER = 'customer';
  C_CUSTOMERS = 'customers';
  C_TOKEN  = 'token';
  C_TOKENS = 'tokens';
  C_PLAN = 'plan';
  C_PLANS = 'plans';
  C_SUBSCRIPTION = 'subscription';
  C_SUBSCRIPTIONS = 'subscriptions';

type
  TStripeBaseObject = class(TInterfacedObject, IStripeBaseObject)
  strict private
    FId: string;
    FObj: string;
  protected
    function DateFromTimeStamp(AJson: TJSONObject; AName: string): TDateTime;
    function GetID: string;
    function GetObj: string;
    function GetObject: string; virtual; abstract;
    procedure LoadFromJson(AJson: TJsonObject); virtual;
    property ID: string read GetID;
    property Obj: string read GetObj;
  public
    constructor Create; virtual;
  end;

  TStripeBaseObjectList = class(TInterfacedObject, IStripeBaseObjectList)
  private
    FItems: TList<TStripeBaseObject>;
  protected
    constructor Create; virtual;
    function CreateObject: IStripeBaseObject; virtual; abstract;
    function AddObject: IStripeBaseObject; virtual;
    function GetListID: string; virtual; abstract;
    procedure Clear;
    procedure LoadFromJson(AJson: TJSONObject);
    function GetItem(index: integer): IStripeBaseObject;
    property Item[index: integer]: IStripeBaseObject read GetItem;
  end;


  TStripePlan = class(TStripeBaseObject, IStripePlan)
  strict private
    FInterval: string;
    FName: string;
    FCreated: TDateTime;
    FAmountPence: integer;
    FCurrency: string;
    FIntervalCount: integer;
    FTrialPeriodDays: integer;
    FStatementDescriptor: string;
  private
    function GetAmountPence: integer;
    function GetCreated: TDateTime;
    function GetCurrency: string;
    function GetInterval: string;
    function GetIntervalCount: integer;
    function GetName: string;
    function GetStatementDescriptor: string;
    function GetTrialPeriodDays: integer;
  protected
    function GetObject: string; override;
    procedure LoadFromJson(AJson: TJsonObject); override;
    property Interval: string read GetInterval;
    property Name: string read GetName;
    property Created: TDateTime read GetCreated;
    property AmountPence: integer read GetAmountPence;
    property Currency: string read GetCurrency;
    property IntervalCount: integer read GetIntervalCount;
    property TrialPeriodDays: integer read GetTrialPeriodDays;
    property StatementDescriptor: string read GetStatementDescriptor;
  end;

  TStripeSubscription = class(TStripeBaseObject, IStripeSubscription)
  strict private
    FPlan: IStripePlan;
    FStart: TDateTime;
    FStatus: string;
    FCustomer: string;
    FCurrentPeriodStart: TDateTime;
    FCurrentPeriodEnd: TDateTime;
    FEndedAt: TDateTime;
    FTrialStart: TDateTime;
    FTrialEnd: TDateTime;
    FCancelledAt: TDateTime;
    FQuantity: integer;
    FTaxPercent: Single;
  private
    function GetCancelledAt: TDateTime;
    function GetCurrentPeriodEnd: TDateTime;
    function GetCurrentPeriodStart: TDateTime;
    function GetCustomer: string;
    function GetEndedAt: TDateTime;
    function GetPlan: IStripePlan;
    function GetQuantity: integer;
    function GetStart: TDateTime;
    function GetStatus: string;
    function GetTaxPercent: single;
    function GetTrialEnd: TDateTime;
    function GetTrialStart: TDateTime;
  protected
    function GetObject: string; override;
    procedure LoadFromJson(AJson: TJsonObject); override;
  public
    constructor Create; override;
    property Plan: IStripePlan read GetPlan;
    property Start: TDateTime read GetStart;
    property Status: string read GetStatus;
    property Customer: string read GetCustomer;
    property CurrentPeriodStart: TDateTime read GetCurrentPeriodStart;
    property CurrentPeriodEnd: TDateTime read GetCurrentPeriodEnd;
    property EndedAt: TDateTime read GetEndedAt;
    property TrialStart: TDateTime read GetTrialStart;
    property TrialEnd: TDateTime read GetTrialEnd;
    property CancelledAt: TDateTime read GetCancelledAt;
    property Quantity: integer read GetQuantity;
    property TaxPercent: single read GetTaxPercent;
  end;

  TStripeSubscriptionList = class(TStripeBaseObjectList, IStripeSubscriptionList)
  protected
    function CreateObject: IStripeBaseObject; override;
    function GetListID: string; override;
  end;

  TStripeCustomer = class(TStripeBaseObject, IStripeCustomer)
  strict private
    FEmail: string;
    FCurrency: string;
    FAccountBalance: integer;
    FSubscriptions: IStripeSubscriptionList;
  private
    function GetAccountBalance: integer;
    function GetCurrency: string;
    function GetEmail: string;
  protected
    function GetObject: string; override;
    procedure LoadFromJson(AJson: TJsonObject); override;
    property Email: string read GetEmail;
    property Currency: string read GetCurrency;
    property AccountBalance: integer read GetAccountBalance;
  public
    constructor Create; virtual;
  end;

  TStripeCustomerList = class(TStripeBaseObjectList, IStripeCusotomerList)
  protected
    function CreateObject: IStripeBaseObject; override;
    function GetListID: string; override;
  end;


  TStripeCard = class(TStripeBaseObject, IStripeCard)
  strict private
    FBrand: string;
    FFunding: string;
    FLast4: string;
    FExpMonth: integer;
    FExpYear: integer;
    FCountry: string;
    FName: string;
    FAddress1: string;
    FAddress2: string;
    FCity: string;
    FState: string;
    FZip: string;
    FAddressCountry: string;
    FCvcCheck: string;
  private
    function GetBrand: string;
    function GetFunding: string;
    function GetLast4: string;
    function GetAddress1: string;
    function GetCountry: string;
    function GetExpMonth: integer;
    function GetExpYear: integer;
    function GetName: string;
    function GetAddress2: string;
    function GetCity: string;
    function GetState: string;
    function GetZip: string;
    function GetAddressCountry: string;
    function GetCvcCheck: string;
  protected
    function GetObject: string; override;
  public
    property Last4: string read GetLast4;
    property Brand: string read GetBrand;
    property Funding: string read GetFunding;
    property ExpMonth: integer read GetExpMonth;
    property ExpYear: integer read GetExpYear;
    property Country: string read GetCountry;
    property Name: string read GetName;
    property Address1: string read GetAddress1;
    property Address2: string read GetAddress2;
    property City: string read GetCity;
    property State: string read GetState;
    property Zip: string read GetZip;
    property AddressCountry: string read GetAddressCountry;
    property CvcCheck: string read GetCvcCheck;
  end;

  TStripe = class(TInterfacedObject, IStripe)
  strict private
    FSecretKey: string;
  private
    procedure CheckForError(AJson: TJsonObject);
    procedure NetHTTPClient1AuthEvent(const Sender: TObject;
                                      AnAuthTarget: TAuthTargetType;
                                      const ARealm, AURL: string; var AUserName,
                                      APassword: string; var AbortAuth: Boolean;
                                      var Persistence: TAuthPersistenceType);
    function CreateHttp: TNetHTTPClient;
    function GetHttp(AMethod: string): string;
    function PostHttp(AToken, AMethod: string; AParams: TStrings): string;
  protected
    function GetCustomer(ACustID: string): IStripeCustomer;
    function CreateToken(ACardNum: string; AExpMonth, AExpYear: integer; ACvc: string): string;
    procedure CreateCharge(AToken, ADescription: string; AAmountPence: integer; const ACurrency: TStripeCurrency = scGbp);
  public
    constructor Create(ASecretKey: string);
  end;


function  CreateStripe(ASecretKey: string): IStripe;
begin
  Result := TStripe.Create(ASecretKey);
end;

function CurrencyToString(ACurrency: TStripeCurrency): string;
begin
  case ACurrency of
    scGbp: Result := 'gbp';
    scUsd: Result := 'usd';
  end;
end;

{ TStripe }

procedure TStripe.CheckForError(AJson: TJsonObject);
var
  AError: TJSONObject;
begin
  if AJson.Values['error'] <> nil then
  begin
    AError := AJson.Values['error'] as TJSONObject;
    raise Exception.Create(AError.Values['message'].Value);
  end;
end;

constructor TStripe.Create(ASecretKey: string);
begin
  inherited Create;
  FSecretKey := ASecretKey;
end;

procedure TStripe.CreateCharge(AToken, ADescription: string; AAmountPence: integer; const ACurrency: TStripeCurrency = scGbp);
var
  AParams: TStrings;
  AResult: string;
  AJson: TJSONObject;
  AError: TJsonObject;
begin
  AParams := TStringList.Create;
  try
    AParams.Values['amount'] := IntToStr(AAmountPence);
    AParams.Values['currency'] := CurrencyToString(ACurrency);
    AResult := PostHttp(AToken, C_CHARGES, AParams);
    AJson := TJSONObject.ParseJSONValue(AResult) as TJSONObject;
    try
      if AJson.Values['error'] <> nil then
      begin
        AError := AJson.Values['error'] as TJsonObject;
        raise Exception.Create(AError.Values['message'].Value);
      end;
    finally
      AJson.Free;
    end;
  finally
    AParams.Free;
  end;
end;

function TStripe.CreateHttp: TNetHTTPClient;
begin
  Result := TNetHTTPClient.Create(nil);
  Result.OnAuthEvent := NetHTTPClient1AuthEvent;
end;

function TStripe.CreateToken(ACardNum: string; AExpMonth, AExpYear: integer;
  ACvc: string): string;
var
  AParams: TStrings;
  AResult: string;
  AJson: TJSONObject;
begin
  AParams := TStringList.Create;
  try
    AParams.Values['card[number]'] := ACardNum;
    AParams.Values['card[exp_month]'] := IntToStr(AExpMonth);;
    AParams.Values['card[exp_year]'] := IntToStr(AExpYear);
    AParams.Values['card[cvc]'] := ACvc;
    AResult := PostHttp('', C_TOKENS,AParams);
    AJson := TJSONObject.ParseJSONValue(AResult) as TJSONObject;
    CheckForError(AJson);
    try
      Result := AJson.Values['id'].Value;
    finally
      AJson.Free;
    end;
  finally
    AParams.Free;
  end;
end;

function TStripe.GetCustomer(ACustID: string): IStripeCustomer;
var
  AResult: string;
  AJson: TJSONObject;
begin
  Result := TStripeCustomer.Create;
  AResult := GetHttp(C_CUSTOMERS+'/'+ACustID);
  AJson := TJSONObject.ParseJSONValue(AResult) as TJSONObject;
  try
    Result.LoadFromJson(AJson);
  finally
    AJson.Free;
  end;
end;

function TStripe.GetHttp(AMethod: string): string;
var
  AHttp: TNetHTTPClient;
  AResponse: IHTTPResponse;
begin
  AHttp := CreateHttp;
  try
    AHttp.CustomHeaders['Authorization'] := 'Bearer '+FSecretKey;
    AResponse := AHttp.Get('https://api.stripe.com/v1/'+AMethod);
    Result := AResponse.ContentAsString
  finally
    AHttp.Free;
  end;
end;

function TStripe.PostHttp(AToken, AMethod: string; AParams: TStrings): string;
var
  AHttp: TNetHTTPClient;
  AResponse: IHTTPResponse;
begin
  AHttp := CreateHttp;
  try
    if AToken <> '' then
      AParams.Values['source'] := AToken;
    AHttp.CustomHeaders['Authorization'] := 'Bearer '+FSecretKey;
    AResponse := AHttp.Post('https://api.stripe.com/v1/'+AMethod, AParams);
    Result := AResponse.ContentAsString
  finally
    AHttp.Free;
  end;
end;

procedure TStripe.NetHTTPClient1AuthEvent(const Sender: TObject;
  AnAuthTarget: TAuthTargetType; const ARealm, AURL: string; var AUserName,
  APassword: string; var AbortAuth: Boolean;
  var Persistence: TAuthPersistenceType);
begin
  if AnAuthTarget = TAuthTargetType.Server then
  begin
    AUserName := FSecretKey;
    APassword := '';
  end;
end;

{ TStripeCard }

function TStripeCard.GetAddress1: string;
begin
  Result := FAddress1;
end;

function TStripeCard.GetAddress2: string;
begin
  Result := FAddress2;
end;

function TStripeCard.GetAddressCountry: string;
begin
  Result := FAddressCountry;
end;

function TStripeCard.GetBrand: string;
begin
  Result := FBrand;
end;

function TStripeCard.GetCity: string;
begin
  Result := FCity;
end;

function TStripeCard.GetCountry: string;
begin
  Result := FCountry;
end;

function TStripeCard.GetCvcCheck: string;
begin
  Result := FCvcCheck;
end;

function TStripeCard.GetExpMonth: integer;
begin
  Result :=FExpMonth;
end;

function TStripeCard.GetExpYear: integer;
begin
  Result := FExpYear;
end;

function TStripeCard.GetFunding: string;
begin
  Result := FFunding;
end;

function TStripeCard.GetLast4: string;
begin
  Result := FLast4;
end;


function TStripeCard.GetName: string;
begin
  Result := FName;
end;


function TStripeCard.GetObject: string;
begin
  Result := C_CARD;
end;

function TStripeCard.GetState: string;
begin
  Result := FState;
end;

function TStripeCard.GetZip: string;
begin
  Result := FZip;
end;

{ TStripeBaseObject }

constructor TStripeBaseObject.Create;
begin
  FId := '';
  FObj := GetObject;
end;

function TStripeBaseObject.DateFromTimeStamp(AJson: TJSONObject;
  AName: string): TDateTime;
var
  ATimestamp: integer;
begin
  ATimestamp := StrToIntDef(AJson.Values[AName].Value, 0);
  Result := UnixToDateTime(ATimestamp);
end;

function TStripeBaseObject.GetID: string;
begin
  Result := FId;
end;

function TStripeBaseObject.GetObj: string;
begin
  Result := FObj;
end;

procedure TStripeBaseObject.LoadFromJson(AJson: TJsonObject);
begin
  FId := AJson.Values['id'].Value;
  FObj := AJson.Values['object'].Value;
end;

{ TStripeCustomer }

constructor TStripeCustomer.Create;
begin
  FSubscriptions := TStripeSubscriptionList.Create;
end;

function TStripeCustomer.GetAccountBalance: integer;
begin
  Result := FAccountBalance;
end;

function TStripeCustomer.GetCurrency: string;
begin
  Result := FCurrency;
end;

function TStripeCustomer.GetEmail: string;
begin
  Result := FEmail;
end;

function TStripeCustomer.GetObject: string;
begin
  Result := C_CUSTOMER;
end;

procedure TStripeCustomer.LoadFromJson(AJson: TJsonObject);
begin
  inherited;
  FEmail := AJson.Values['email'].Value;
  FCurrency := AJson.Values['currency'].Value;
  FAccountBalance := StrToIntDef(AJson.Values['account_balance'].Value, 0);
  FSubscriptions.LoadFromJson(AJson);
end;

{ TStripePlan }

function TStripePlan.GetAmountPence: integer;
begin
  Result := FAmountPence;
end;

function TStripePlan.GetCreated: TDateTime;
begin
  Result := FCreated;
end;

function TStripePlan.GetCurrency: string;
begin
  Result := FCurrency;
end;

function TStripePlan.GetInterval: string;
begin
  Result := FInterval;
end;

function TStripePlan.GetIntervalCount: integer;
begin
  Result := FIntervalCount;
end;

function TStripePlan.GetName: string;
begin
  Result := FName;
end;

function TStripePlan.GetObject: string;
begin
  Result := C_PLAN;
end;

function TStripePlan.GetStatementDescriptor: string;
begin
  Result := FStatementDescriptor;
end;

function TStripePlan.GetTrialPeriodDays: integer;
begin
  Result := FTrialPeriodDays;
end;

procedure TStripePlan.LoadFromJson(AJson: TJsonObject);
begin
  inherited;
  FInterval := AJson.Values['interval'].Value;
  FName := AJson.Values['name'].Value;
  FCreated := DateFromTimeStamp(AJson, 'created');
  FAmountPence := StrToIntDef(AJson.Values['amount'].Value, 0);
  FCurrency := AJson.Values['currency'].Value;
  FIntervalCount := StrToIntDef(AJson.Values['interval_count'].Value, 0);
  FTrialPeriodDays := StrToIntDef(AJson.Values['trial_period_days'].Value, 0);
  FStatementDescriptor := AJson.Values['statement_descriptor'].Value;
end;

{ TStripeSubscription }

constructor TStripeSubscription.Create;
begin
  inherited;
  FPlan := TStripePlan.Create;
end;

function TStripeSubscription.GetCancelledAt: TDateTime;
begin
  Result := FCancelledAt;
end;

function TStripeSubscription.GetCurrentPeriodEnd: TDateTime;
begin
  Result := FCurrentPeriodEnd;
end;

function TStripeSubscription.GetCurrentPeriodStart: TDateTime;
begin
  Result := FCurrentPeriodStart;
end;

function TStripeSubscription.GetCustomer: string;
begin
  Result := FCustomer;
end;

function TStripeSubscription.GetEndedAt: TDateTime;
begin
  Result := FEndedAt;
end;

function TStripeSubscription.GetObject: string;
begin
  Result := C_SUBSCRIPTION;
end;

function TStripeSubscription.GetPlan: IStripePlan;
begin
  Result := FPlan;
end;

function TStripeSubscription.GetQuantity: integer;
begin
  Result := FQuantity;
end;

function TStripeSubscription.GetStart: TDateTime;
begin
  Result := FStart;
end;

function TStripeSubscription.GetStatus: string;
begin
  Result := FStatus;
end;

function TStripeSubscription.GetTaxPercent: single;
begin
  Result := FTaxPercent;
end;

function TStripeSubscription.GetTrialEnd: TDateTime;
begin
  Result := FTrialEnd;
end;

function TStripeSubscription.GetTrialStart: TDateTime;
begin
  Result := FTrialStart;
end;

procedure TStripeSubscription.LoadFromJson(AJson: TJsonObject);
begin
  inherited;
  FPlan.LoadFromJson(AJson.Values['plan'] as TJSONObject);
  FStatus := AJson.Values['status'].Value;
end;

{ TStripeBaseObjectList<T> }

function TStripeBaseObjectList.AddObject: IStripeBaseObject;
begin
  Result := CreateObject;
  FItems.Add(Result as TStripeBaseObject);
end;

procedure TStripeBaseObjectList.Clear;
begin
  FItems.Clear;
end;

constructor TStripeBaseObjectList.Create;
begin
  FItems := TList<TStripeBaseObject>.Create;
end;

function TStripeBaseObjectList.GetItem(index: integer): IStripeBaseObject;
begin
  Result := FItems[index];
end;

procedure TStripeBaseObjectList.LoadFromJson(AJson: TJSONObject);
var
  AObj: TJSONObject;
  AArray: TJSONArray;
  ICount: integer;
begin
  Clear;
  AObj := AJson.Values[GetListID] as TJSONObject;
  AArray := AObj.Values['data'] as TJSONArray;
  for ICount := 0 to AArray.Count-1 do
  begin
    AddObject.LoadFromJson(AArray.Items[ICount] as TJsonObject);
  end;
end;


{ TStripeCustomerList }

function TStripeCustomerList.CreateObject: IStripeBaseObject;
begin
  Result := TStripeCustomer.Create;
end;

function TStripeCustomerList.GetListID: string;
begin
  Result := C_CUSTOMERS;
end;

{ TStripeSubscriptionList }

function TStripeSubscriptionList.CreateObject: IStripeBaseObject;
begin
  Result := TStripeSubscription.Create;
end;

function TStripeSubscriptionList.GetListID: string;
begin
  Result := C_SUBSCRIPTIONS;
end;

end.