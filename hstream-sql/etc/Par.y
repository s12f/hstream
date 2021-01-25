-- This Happy file was machine-generated by the BNF converter
{
{-# OPTIONS_GHC -fno-warn-incomplete-patterns -fno-warn-overlapping-patterns #-}
module Language.SQL.Par where
import qualified Language.SQL.Abs
import Language.SQL.Lex
import qualified Data.Text
}

%name pSQL_internal SQL
%name pCreate_internal Create
%name pListStreamOption_internal ListStreamOption
%name pStreamOption_internal StreamOption
%name pInsert_internal Insert
%name pListIdent_internal ListIdent
%name pListValueExpr_internal ListValueExpr
%name pSelect_internal Select
%name pSel_internal Sel
%name pSelList_internal SelList
%name pListDerivedCol_internal ListDerivedCol
%name pDerivedCol_internal DerivedCol
%name pFrom_internal From
%name pListTableRef_internal ListTableRef
%name pTableRef_internal TableRef
%name pJoinType_internal JoinType
%name pJoinWindow_internal JoinWindow
%name pJoinCond_internal JoinCond
%name pWhere_internal Where
%name pGroupBy_internal GroupBy
%name pListGrpItem_internal ListGrpItem
%name pGrpItem_internal GrpItem
%name pWindow_internal Window
%name pHaving_internal Having
%name pValueExpr_internal ValueExpr
%name pValueExpr1_internal ValueExpr1
%name pValueExpr2_internal ValueExpr2
%name pDate_internal Date
%name pTime_internal Time
%name pTimeUnit_internal TimeUnit
%name pInterval_internal Interval
%name pListLabelledValueExpr_internal ListLabelledValueExpr
%name pLabelledValueExpr_internal LabelledValueExpr
%name pColName_internal ColName
%name pSetFunc_internal SetFunc
%name pSearchCond_internal SearchCond
%name pSearchCond1_internal SearchCond1
%name pSearchCond2_internal SearchCond2
%name pSearchCond3_internal SearchCond3
%name pCompOp_internal CompOp
-- no lexer declaration
%monad { Either String } { (>>=) } { return }
%tokentype {Token}
%token
  '(' { PT _ (TS _ 1) }
  ')' { PT _ (TS _ 2) }
  '*' { PT _ (TS _ 3) }
  '+' { PT _ (TS _ 4) }
  ',' { PT _ (TS _ 5) }
  '-' { PT _ (TS _ 6) }
  '.' { PT _ (TS _ 7) }
  ':' { PT _ (TS _ 8) }
  ';' { PT _ (TS _ 9) }
  '<' { PT _ (TS _ 10) }
  '<=' { PT _ (TS _ 11) }
  '<>' { PT _ (TS _ 12) }
  '=' { PT _ (TS _ 13) }
  '>' { PT _ (TS _ 14) }
  '>=' { PT _ (TS _ 15) }
  'AND' { PT _ (TS _ 16) }
  'AS' { PT _ (TS _ 17) }
  'AVG' { PT _ (TS _ 18) }
  'BETWEEN' { PT _ (TS _ 19) }
  'BY' { PT _ (TS _ 20) }
  'COUNT' { PT _ (TS _ 21) }
  'COUNT(*)' { PT _ (TS _ 22) }
  'CREATE' { PT _ (TS _ 23) }
  'CROSS' { PT _ (TS _ 24) }
  'DATE' { PT _ (TS _ 25) }
  'DAY' { PT _ (TS _ 26) }
  'FORMAT' { PT _ (TS _ 27) }
  'FROM' { PT _ (TS _ 28) }
  'FULL' { PT _ (TS _ 29) }
  'GROUP' { PT _ (TS _ 30) }
  'HAVING' { PT _ (TS _ 31) }
  'HOPPING' { PT _ (TS _ 32) }
  'INSERT' { PT _ (TS _ 33) }
  'INTERVAL' { PT _ (TS _ 34) }
  'INTO' { PT _ (TS _ 35) }
  'JOIN' { PT _ (TS _ 36) }
  'LEFT' { PT _ (TS _ 37) }
  'MAX' { PT _ (TS _ 38) }
  'MIN' { PT _ (TS _ 39) }
  'MINUTE' { PT _ (TS _ 40) }
  'MONTH' { PT _ (TS _ 41) }
  'NOT' { PT _ (TS _ 42) }
  'ON' { PT _ (TS _ 43) }
  'OR' { PT _ (TS _ 44) }
  'RIGHT' { PT _ (TS _ 45) }
  'SECOND' { PT _ (TS _ 46) }
  'SELECT' { PT _ (TS _ 47) }
  'SESSION' { PT _ (TS _ 48) }
  'STREAM' { PT _ (TS _ 49) }
  'SUM' { PT _ (TS _ 50) }
  'TIME' { PT _ (TS _ 51) }
  'TUMBLING' { PT _ (TS _ 52) }
  'VALUES' { PT _ (TS _ 53) }
  'WEEK' { PT _ (TS _ 54) }
  'WHERE' { PT _ (TS _ 55) }
  'WITH' { PT _ (TS _ 56) }
  'WITHIN' { PT _ (TS _ 57) }
  'YEAR' { PT _ (TS _ 58) }
  '[' { PT _ (TS _ 59) }
  ']' { PT _ (TS _ 60) }
  '{' { PT _ (TS _ 61) }
  '}' { PT _ (TS _ 62) }
  L_Ident  { PT _ (TV _) }
  L_doubl  { PT _ (TD _) }
  L_integ  { PT _ (TI _) }
  L_quoted { PT _ (TL _) }

%%

Ident :: { (Maybe (Int, Int), Language.SQL.Abs.Ident) }
Ident  : L_Ident { (Just (tokenLineCol $1), Language.SQL.Abs.Ident (tokenText $1)) }

Double  :: { (Maybe (Int, Int), Double) }
Double   : L_doubl  { (Just (tokenLineCol $1), (read (Data.Text.unpack (tokenText $1))) :: Double) }

Integer :: { (Maybe (Int, Int), Integer) }
Integer  : L_integ  { (Just (tokenLineCol $1), (read (Data.Text.unpack (tokenText $1))) :: Integer) }

String  :: { (Maybe (Int, Int), String) }
String   : L_quoted { (Just (tokenLineCol $1), Data.Text.unpack (tokenText $1)) }

SQL :: { (Maybe (Int, Int),  (Language.SQL.Abs.SQL (Maybe (Int, Int))) ) }
SQL : Select ';' { (fst $1, Language.SQL.Abs.QSelect (fst $1) (snd $1)) }
    | Create ';' { (fst $1, Language.SQL.Abs.QCreate (fst $1) (snd $1)) }
    | Insert ';' { (fst $1, Language.SQL.Abs.QInsert (fst $1) (snd $1)) }

Create :: { (Maybe (Int, Int),  (Language.SQL.Abs.Create (Maybe (Int, Int))) ) }
Create : 'CREATE' 'STREAM' Ident 'WITH' '(' ListStreamOption ')' { (Just (tokenLineCol $1), Language.SQL.Abs.DCreate (Just (tokenLineCol $1)) (snd $3) (snd $6)) }
       | 'CREATE' 'STREAM' Ident 'AS' Select 'WITH' '(' ListStreamOption ')' { (Just (tokenLineCol $1), Language.SQL.Abs.CreateAs (Just (tokenLineCol $1)) (snd $3) (snd $5) (snd $8)) }

ListStreamOption :: { (Maybe (Int, Int),  [Language.SQL.Abs.StreamOption (Maybe (Int, Int))] ) }
ListStreamOption : {- empty -} { (Nothing, []) }
                 | StreamOption { (fst $1, (:[]) (snd $1)) }
                 | StreamOption ',' ListStreamOption { (fst $1, (:) (snd $1) (snd $3)) }

StreamOption :: { (Maybe (Int, Int),  (Language.SQL.Abs.StreamOption (Maybe (Int, Int))) ) }
StreamOption : 'FORMAT' '=' String { (Just (tokenLineCol $1), Language.SQL.Abs.OptionFormat (Just (tokenLineCol $1)) (snd $3)) }

Insert :: { (Maybe (Int, Int),  (Language.SQL.Abs.Insert (Maybe (Int, Int))) ) }
Insert : 'INSERT' 'INTO' Ident '(' ListIdent ')' 'VALUES' '(' ListValueExpr ')' { (Just (tokenLineCol $1), Language.SQL.Abs.DInsert (Just (tokenLineCol $1)) (snd $3) (snd $5) (snd $9)) }

ListIdent :: { (Maybe (Int, Int),  [Language.SQL.Abs.Ident] ) }
ListIdent : {- empty -} { (Nothing, []) }
          | Ident { (fst $1, (:[]) (snd $1)) }
          | Ident ',' ListIdent { (fst $1, (:) (snd $1) (snd $3)) }

ListValueExpr :: { (Maybe (Int, Int),  [Language.SQL.Abs.ValueExpr (Maybe (Int, Int))] ) }
ListValueExpr : {- empty -} { (Nothing, []) }
              | ValueExpr { (fst $1, (:[]) (snd $1)) }
              | ValueExpr ',' ListValueExpr { (fst $1, (:) (snd $1) (snd $3)) }

Select :: { (Maybe (Int, Int),  (Language.SQL.Abs.Select (Maybe (Int, Int))) ) }
Select : Sel From Where GroupBy Having { (fst $1, Language.SQL.Abs.DSelect (fst $1) (snd $1) (snd $2) (snd $3) (snd $4) (snd $5)) }

Sel :: { (Maybe (Int, Int),  (Language.SQL.Abs.Sel (Maybe (Int, Int))) ) }
Sel : 'SELECT' SelList { (Just (tokenLineCol $1), Language.SQL.Abs.DSel (Just (tokenLineCol $1)) (snd $2)) }

SelList :: { (Maybe (Int, Int),  (Language.SQL.Abs.SelList (Maybe (Int, Int))) ) }
SelList : '*' { (Just (tokenLineCol $1), Language.SQL.Abs.SelListAsterisk (Just (tokenLineCol $1))) }
        | ListDerivedCol { (fst $1, Language.SQL.Abs.SelListSublist (fst $1) (snd $1)) }

ListDerivedCol :: { (Maybe (Int, Int),  [Language.SQL.Abs.DerivedCol (Maybe (Int, Int))] ) }
ListDerivedCol : {- empty -} { (Nothing, []) }
               | DerivedCol { (fst $1, (:[]) (snd $1)) }
               | DerivedCol ',' ListDerivedCol { (fst $1, (:) (snd $1) (snd $3)) }

DerivedCol :: { (Maybe (Int, Int),  (Language.SQL.Abs.DerivedCol (Maybe (Int, Int))) ) }
DerivedCol : ValueExpr { (fst $1, Language.SQL.Abs.DerivedColSimpl (fst $1) (snd $1)) }
           | ValueExpr 'AS' Ident { (fst $1, Language.SQL.Abs.DerivedColAs (fst $1) (snd $1) (snd $3)) }

From :: { (Maybe (Int, Int),  (Language.SQL.Abs.From (Maybe (Int, Int))) ) }
From : 'FROM' ListTableRef { (Just (tokenLineCol $1), Language.SQL.Abs.DFrom (Just (tokenLineCol $1)) (snd $2)) }

ListTableRef :: { (Maybe (Int, Int),  [Language.SQL.Abs.TableRef (Maybe (Int, Int))] ) }
ListTableRef : {- empty -} { (Nothing, []) }
             | TableRef { (fst $1, (:[]) (snd $1)) }
             | TableRef ',' ListTableRef { (fst $1, (:) (snd $1) (snd $3)) }

TableRef :: { (Maybe (Int, Int),  (Language.SQL.Abs.TableRef (Maybe (Int, Int))) ) }
TableRef : Ident { (fst $1, Language.SQL.Abs.TableRefSimple (fst $1) (snd $1)) }
         | TableRef 'AS' Ident { (fst $1, Language.SQL.Abs.TableRefAs (fst $1) (snd $1) (snd $3)) }
         | TableRef JoinType 'JOIN' TableRef JoinWindow JoinCond { (fst $1, Language.SQL.Abs.TableRefJoin (fst $1) (snd $1) (snd $2) (snd $4) (snd $5) (snd $6)) }

JoinType :: { (Maybe (Int, Int),  (Language.SQL.Abs.JoinType (Maybe (Int, Int))) ) }
JoinType : 'LEFT' { (Just (tokenLineCol $1), Language.SQL.Abs.JoinLeft (Just (tokenLineCol $1))) }
         | 'RIGHT' { (Just (tokenLineCol $1), Language.SQL.Abs.JoinRight (Just (tokenLineCol $1))) }
         | 'FULL' { (Just (tokenLineCol $1), Language.SQL.Abs.JoinFull (Just (tokenLineCol $1))) }
         | 'CROSS' { (Just (tokenLineCol $1), Language.SQL.Abs.JoinCross (Just (tokenLineCol $1))) }

JoinWindow :: { (Maybe (Int, Int),  (Language.SQL.Abs.JoinWindow (Maybe (Int, Int))) ) }
JoinWindow : 'WITHIN' '(' Interval ')' { (Just (tokenLineCol $1), Language.SQL.Abs.DJoinWindow (Just (tokenLineCol $1)) (snd $3)) }

JoinCond :: { (Maybe (Int, Int),  (Language.SQL.Abs.JoinCond (Maybe (Int, Int))) ) }
JoinCond : 'ON' SearchCond { (Just (tokenLineCol $1), Language.SQL.Abs.DJoinCond (Just (tokenLineCol $1)) (snd $2)) }

Where :: { (Maybe (Int, Int),  (Language.SQL.Abs.Where (Maybe (Int, Int))) ) }
Where : {- empty -} { (Nothing, Language.SQL.Abs.DWhereEmpty (Nothing)) }
      | 'WHERE' SearchCond { (Just (tokenLineCol $1), Language.SQL.Abs.DWhere (Just (tokenLineCol $1)) (snd $2)) }

GroupBy :: { (Maybe (Int, Int),  (Language.SQL.Abs.GroupBy (Maybe (Int, Int))) ) }
GroupBy : {- empty -} { (Nothing, Language.SQL.Abs.DGroupByEmpty (Nothing)) }
        | 'GROUP' 'BY' ListGrpItem { (Just (tokenLineCol $1), Language.SQL.Abs.DGroupBy (Just (tokenLineCol $1)) (snd $3)) }

ListGrpItem :: { (Maybe (Int, Int),  [Language.SQL.Abs.GrpItem (Maybe (Int, Int))] ) }
ListGrpItem : {- empty -} { (Nothing, []) }
            | GrpItem { (fst $1, (:[]) (snd $1)) }
            | GrpItem ',' ListGrpItem { (fst $1, (:) (snd $1) (snd $3)) }

GrpItem :: { (Maybe (Int, Int),  (Language.SQL.Abs.GrpItem (Maybe (Int, Int))) ) }
GrpItem : ColName { (fst $1, Language.SQL.Abs.GrpItemCol (fst $1) (snd $1)) }
        | Window { (fst $1, Language.SQL.Abs.GrpItemWin (fst $1) (snd $1)) }

Window :: { (Maybe (Int, Int),  (Language.SQL.Abs.Window (Maybe (Int, Int))) ) }
Window : 'TUMBLING' '(' Interval ')' { (Just (tokenLineCol $1), Language.SQL.Abs.TumblingWindow (Just (tokenLineCol $1)) (snd $3)) }
       | 'HOPPING' '(' Interval ',' Interval ')' { (Just (tokenLineCol $1), Language.SQL.Abs.HoppingWindow (Just (tokenLineCol $1)) (snd $3) (snd $5)) }
       | 'SESSION' '(' Interval ')' { (Just (tokenLineCol $1), Language.SQL.Abs.SessionWindow (Just (tokenLineCol $1)) (snd $3)) }

Having :: { (Maybe (Int, Int),  (Language.SQL.Abs.Having (Maybe (Int, Int))) ) }
Having : {- empty -} { (Nothing, Language.SQL.Abs.DHavingEmpty (Nothing)) }
       | 'HAVING' SearchCond { (Just (tokenLineCol $1), Language.SQL.Abs.DHaving (Just (tokenLineCol $1)) (snd $2)) }

ValueExpr :: { (Maybe (Int, Int),  (Language.SQL.Abs.ValueExpr (Maybe (Int, Int))) ) }
ValueExpr : ValueExpr '+' ValueExpr1 { (fst $1, Language.SQL.Abs.ExprAdd (fst $1) (snd $1) (snd $3)) }
          | ValueExpr '-' ValueExpr1 { (fst $1, Language.SQL.Abs.ExprSub (fst $1) (snd $1) (snd $3)) }
          | '[' ListValueExpr ']' { (Just (tokenLineCol $1), Language.SQL.Abs.ExprArr (Just (tokenLineCol $1)) (snd $2)) }
          | '{' ListLabelledValueExpr '}' { (Just (tokenLineCol $1), Language.SQL.Abs.ExprMap (Just (tokenLineCol $1)) (snd $2)) }
          | ValueExpr1 { (fst $1, (snd $1)) }

ValueExpr1 :: { (Maybe (Int, Int),  Language.SQL.Abs.ValueExpr (Maybe (Int, Int)) ) }
ValueExpr1 : ValueExpr1 '*' ValueExpr2 { (fst $1, Language.SQL.Abs.ExprMul (fst $1) (snd $1) (snd $3)) }
           | ValueExpr2 { (fst $1, (snd $1)) }

ValueExpr2 :: { (Maybe (Int, Int),  Language.SQL.Abs.ValueExpr (Maybe (Int, Int)) ) }
ValueExpr2 : Integer { (fst $1, Language.SQL.Abs.ExprInt (fst $1) (snd $1)) }
           | Double { (fst $1, Language.SQL.Abs.ExprNum (fst $1) (snd $1)) }
           | String { (fst $1, Language.SQL.Abs.ExprString (fst $1) (snd $1)) }
           | Date { (fst $1, Language.SQL.Abs.ExprDate (fst $1) (snd $1)) }
           | Time { (fst $1, Language.SQL.Abs.ExprTime (fst $1) (snd $1)) }
           | Interval { (fst $1, Language.SQL.Abs.ExprInterval (fst $1) (snd $1)) }
           | ColName { (fst $1, Language.SQL.Abs.ExprColName (fst $1) (snd $1)) }
           | SetFunc { (fst $1, Language.SQL.Abs.ExprSetFunc (fst $1) (snd $1)) }
           | '(' ValueExpr ')' { (Just (tokenLineCol $1), (snd $2)) }

Date :: { (Maybe (Int, Int),  (Language.SQL.Abs.Date (Maybe (Int, Int))) ) }
Date : 'DATE' Integer '-' Integer '-' Integer { (Just (tokenLineCol $1), Language.SQL.Abs.DDate (Just (tokenLineCol $1)) (snd $2) (snd $4) (snd $6)) }

Time :: { (Maybe (Int, Int),  (Language.SQL.Abs.Time (Maybe (Int, Int))) ) }
Time : 'TIME' Integer ':' Integer ':' Integer { (Just (tokenLineCol $1), Language.SQL.Abs.DTime (Just (tokenLineCol $1)) (snd $2) (snd $4) (snd $6)) }

TimeUnit :: { (Maybe (Int, Int),  (Language.SQL.Abs.TimeUnit (Maybe (Int, Int))) ) }
TimeUnit : 'YEAR' { (Just (tokenLineCol $1), Language.SQL.Abs.TimeUnitYear (Just (tokenLineCol $1))) }
         | 'MONTH' { (Just (tokenLineCol $1), Language.SQL.Abs.TimeUnitMonth (Just (tokenLineCol $1))) }
         | 'WEEK' { (Just (tokenLineCol $1), Language.SQL.Abs.TimeUnitWeek (Just (tokenLineCol $1))) }
         | 'DAY' { (Just (tokenLineCol $1), Language.SQL.Abs.TimeUnitDay (Just (tokenLineCol $1))) }
         | 'MINUTE' { (Just (tokenLineCol $1), Language.SQL.Abs.TimeUnitMin (Just (tokenLineCol $1))) }
         | 'SECOND' { (Just (tokenLineCol $1), Language.SQL.Abs.TimeUnitSec (Just (tokenLineCol $1))) }

Interval :: { (Maybe (Int, Int),  (Language.SQL.Abs.Interval (Maybe (Int, Int))) ) }
Interval : 'INTERVAL' Integer TimeUnit { (Just (tokenLineCol $1), Language.SQL.Abs.DInterval (Just (tokenLineCol $1)) (snd $2) (snd $3)) }

ListLabelledValueExpr :: { (Maybe (Int, Int),  [Language.SQL.Abs.LabelledValueExpr (Maybe (Int, Int))] ) }
ListLabelledValueExpr : {- empty -} { (Nothing, []) }
                      | LabelledValueExpr { (fst $1, (:[]) (snd $1)) }
                      | LabelledValueExpr ',' ListLabelledValueExpr { (fst $1, (:) (snd $1) (snd $3)) }

LabelledValueExpr :: { (Maybe (Int, Int),  (Language.SQL.Abs.LabelledValueExpr (Maybe (Int, Int))) ) }
LabelledValueExpr : Ident ':' ValueExpr { (fst $1, Language.SQL.Abs.DLabelledValueExpr (fst $1) (snd $1) (snd $3)) }

ColName :: { (Maybe (Int, Int),  (Language.SQL.Abs.ColName (Maybe (Int, Int))) ) }
ColName : Ident { (fst $1, Language.SQL.Abs.ColNameSimple (fst $1) (snd $1)) }
        | Ident '.' Ident { (fst $1, Language.SQL.Abs.ColNameStream (fst $1) (snd $1) (snd $3)) }
        | ColName '[' Ident ']' { (fst $1, Language.SQL.Abs.ColNameInner (fst $1) (snd $1) (snd $3)) }
        | ColName '[' Integer ']' { (fst $1, Language.SQL.Abs.ColNameIndex (fst $1) (snd $1) (snd $3)) }

SetFunc :: { (Maybe (Int, Int),  (Language.SQL.Abs.SetFunc (Maybe (Int, Int))) ) }
SetFunc : 'COUNT(*)' { (Just (tokenLineCol $1), Language.SQL.Abs.SetFuncCountAll (Just (tokenLineCol $1))) }
        | 'COUNT' '(' ValueExpr ')' { (Just (tokenLineCol $1), Language.SQL.Abs.SetFuncCount (Just (tokenLineCol $1)) (snd $3)) }
        | 'AVG' '(' ValueExpr ')' { (Just (tokenLineCol $1), Language.SQL.Abs.SetFuncAvg (Just (tokenLineCol $1)) (snd $3)) }
        | 'SUM' '(' ValueExpr ')' { (Just (tokenLineCol $1), Language.SQL.Abs.SetFuncSum (Just (tokenLineCol $1)) (snd $3)) }
        | 'MAX' '(' ValueExpr ')' { (Just (tokenLineCol $1), Language.SQL.Abs.SetFuncMax (Just (tokenLineCol $1)) (snd $3)) }
        | 'MIN' '(' ValueExpr ')' { (Just (tokenLineCol $1), Language.SQL.Abs.SetFuncMin (Just (tokenLineCol $1)) (snd $3)) }

SearchCond :: { (Maybe (Int, Int),  (Language.SQL.Abs.SearchCond (Maybe (Int, Int))) ) }
SearchCond : SearchCond 'OR' SearchCond1 { (fst $1, Language.SQL.Abs.CondOr (fst $1) (snd $1) (snd $3)) }
           | SearchCond1 { (fst $1, (snd $1)) }

SearchCond1 :: { (Maybe (Int, Int),  Language.SQL.Abs.SearchCond (Maybe (Int, Int)) ) }
SearchCond1 : SearchCond1 'AND' SearchCond2 { (fst $1, Language.SQL.Abs.CondAnd (fst $1) (snd $1) (snd $3)) }
            | SearchCond2 { (fst $1, (snd $1)) }

SearchCond2 :: { (Maybe (Int, Int),  Language.SQL.Abs.SearchCond (Maybe (Int, Int)) ) }
SearchCond2 : 'NOT' SearchCond3 { (Just (tokenLineCol $1), Language.SQL.Abs.CondNot (Just (tokenLineCol $1)) (snd $2)) }
            | SearchCond3 { (fst $1, (snd $1)) }

SearchCond3 :: { (Maybe (Int, Int),  Language.SQL.Abs.SearchCond (Maybe (Int, Int)) ) }
SearchCond3 : ValueExpr CompOp ValueExpr { (fst $1, Language.SQL.Abs.CondOp (fst $1) (snd $1) (snd $2) (snd $3)) }
            | ValueExpr 'BETWEEN' ValueExpr 'AND' ValueExpr { (fst $1, Language.SQL.Abs.CondBetween (fst $1) (snd $1) (snd $3) (snd $5)) }
            | '(' SearchCond ')' { (Just (tokenLineCol $1), (snd $2)) }

CompOp :: { (Maybe (Int, Int),  (Language.SQL.Abs.CompOp (Maybe (Int, Int))) ) }
CompOp : '=' { (Just (tokenLineCol $1), Language.SQL.Abs.CompOpEQ (Just (tokenLineCol $1))) }
       | '<>' { (Just (tokenLineCol $1), Language.SQL.Abs.CompOpNE (Just (tokenLineCol $1))) }
       | '<' { (Just (tokenLineCol $1), Language.SQL.Abs.CompOpLT (Just (tokenLineCol $1))) }
       | '>' { (Just (tokenLineCol $1), Language.SQL.Abs.CompOpGT (Just (tokenLineCol $1))) }
       | '<=' { (Just (tokenLineCol $1), Language.SQL.Abs.CompOpLEQ (Just (tokenLineCol $1))) }
       | '>=' { (Just (tokenLineCol $1), Language.SQL.Abs.CompOpGEQ (Just (tokenLineCol $1))) }
{

happyError :: [Token] -> Either String a
happyError ts = Left $
  "syntax error at " ++ tokenPos ts ++
  case ts of
    []      -> []
    [Err _] -> " due to lexer error"
    t:_     -> " before `" ++ (prToken t) ++ "'"

myLexer = tokens
pSQL = (>>= return . snd) . pSQL_internal
pCreate = (>>= return . snd) . pCreate_internal
pListStreamOption = (>>= return . snd) . pListStreamOption_internal
pStreamOption = (>>= return . snd) . pStreamOption_internal
pInsert = (>>= return . snd) . pInsert_internal
pListIdent = (>>= return . snd) . pListIdent_internal
pListValueExpr = (>>= return . snd) . pListValueExpr_internal
pSelect = (>>= return . snd) . pSelect_internal
pSel = (>>= return . snd) . pSel_internal
pSelList = (>>= return . snd) . pSelList_internal
pListDerivedCol = (>>= return . snd) . pListDerivedCol_internal
pDerivedCol = (>>= return . snd) . pDerivedCol_internal
pFrom = (>>= return . snd) . pFrom_internal
pListTableRef = (>>= return . snd) . pListTableRef_internal
pTableRef = (>>= return . snd) . pTableRef_internal
pJoinType = (>>= return . snd) . pJoinType_internal
pJoinWindow = (>>= return . snd) . pJoinWindow_internal
pJoinCond = (>>= return . snd) . pJoinCond_internal
pWhere = (>>= return . snd) . pWhere_internal
pGroupBy = (>>= return . snd) . pGroupBy_internal
pListGrpItem = (>>= return . snd) . pListGrpItem_internal
pGrpItem = (>>= return . snd) . pGrpItem_internal
pWindow = (>>= return . snd) . pWindow_internal
pHaving = (>>= return . snd) . pHaving_internal
pValueExpr = (>>= return . snd) . pValueExpr_internal
pValueExpr1 = (>>= return . snd) . pValueExpr1_internal
pValueExpr2 = (>>= return . snd) . pValueExpr2_internal
pDate = (>>= return . snd) . pDate_internal
pTime = (>>= return . snd) . pTime_internal
pTimeUnit = (>>= return . snd) . pTimeUnit_internal
pInterval = (>>= return . snd) . pInterval_internal
pListLabelledValueExpr = (>>= return . snd) . pListLabelledValueExpr_internal
pLabelledValueExpr = (>>= return . snd) . pLabelledValueExpr_internal
pColName = (>>= return . snd) . pColName_internal
pSetFunc = (>>= return . snd) . pSetFunc_internal
pSearchCond = (>>= return . snd) . pSearchCond_internal
pSearchCond1 = (>>= return . snd) . pSearchCond1_internal
pSearchCond2 = (>>= return . snd) . pSearchCond2_internal
pSearchCond3 = (>>= return . snd) . pSearchCond3_internal
pCompOp = (>>= return . snd) . pCompOp_internal
}

