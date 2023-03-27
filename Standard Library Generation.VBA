Const OUTPUT_FOLDER = "C:\...\Standard Module CAD Library\Pallet\Roller Straight\Sections\Library Generation Related\Macro-Generated Drawings"

Const BASE_VIEWS_ONLY        As Boolean = True
Dim swApp                    As SldWorks.SldWorks
Dim swModel                  As SldWorks.ModelDoc2
Dim swDraw                   As SldWorks.DrawingDoc
Dim swRefModel               As SldWorks.ModelDoc2

Sub main()

Dim i         As Integer
Dim vConfs    As Variant
Dim swView    As SldWorks.View
Dim confname  As String
Dim filename  As String
Dim sType     As String

Set swApp = Application.SldWorks
Set swModel = swApp.ActiveDoc

'   Make sure the macro is being run on a drawing
If Not swModel.GetType() = swDocumentTypes_e.swDocDRAWING Then
    MsgBox "Please open a drawing"
    GoTo Finally
End If

Set swDraw = swModel
Set swView = swDraw.GetFirstView().GetNextView
Set swRefModel = swView.ReferencedDocument

vConfs = swRefModel.GetConfigurationNames

'   Do the algorithm for each configuration
For i = 0 To UBound(vConfs)

    filename = swModel.GetPathName
    sType = Left(Right(filename, 9), 2)
    confname = vConfs(i)
    
'   Skip Flat Pattern derrived configurations
    If InStr(confname, "FLAT-PATTERN") Then
    GoTo Skip
    End If

'   Changes configuration of all views on all sheets
    ProcessViews confname
    swModel.ForceRebuild3 False
    Dim Errors As Long, Warnings As Long

'   Deletes old balloons and reinserts if the file is an assembly
    If InStr(confname, "-GA") Or InStr(confname, "-F") Then
        DeleteBalloons
        AutoBalloon
    End If

'   If the last two characters of a config are "-L" this changes the flat pattern configuration
    If sType = "-L" Then
        boolstatus = swDraw.ActivateView("FLAT")
        boolstatus = swDraw.Extension.SelectByID2("FLAT", "DRAWINGVIEW", 0, 0, 0, False, 0, Nothing, 0)
        boolstatus = swDraw.ChangeRefConfigurationOfFlatPatternView(filename, confname)
        swView.UseSheetScale = 1
        swModel.ForceRebuild3 False
        Else
    End If

    AutoScale (confname) 'self explanatory

'   If a configuration is derrived (flat pattern) it won't be saved
    If Not Right(confname, 12) = "FLAT-PATTERN" Then
    boolstatus = swDraw.Extension.SaveAs(OUTPUT_FOLDER + "\" + confname + ".slddrw", swSaveAsVersion_e.swSaveAsCurrentVersion, swSaveAsOptions_e.swSaveAsOptions_Copy, Nothing, Errors, Warnings)
    Else
    End If

Skip:
Next i

MsgBox "Completed"

Finally:
End Sub

Sub ProcessViews(confname As String)

Dim i As Integer
Dim vsheets As Variant
Dim j As Integer
Dim vViews As Variant
Dim swFeat As SldWorks.Feature
Dim swView As SldWorks.View
Dim sName As String

'   Get all views on all sheets and change each
'   to the current configuration being cycled through
vsheets = swDraw.GetViews

For i = 0 To UBound(vsheets)

    vViews = vsheets(i)

    For j = 0 To UBound(vViews)

        Set swView = vViews(j)
        
'       Skips the flat pattern from being activated in the views
        sName = swView.GetName2
        If InStr(sName, "FLAT") Then
            GoTo Skip:
        End If
        
        swView.ReferencedConfiguration = confname

Skip:
    Next j

'   Cycle drawing features to find a BOM
    Set swFeat = swDraw.FirstFeature

        While Not swFeat Is Nothing

            If "BomFeat" = swFeat.GetTypeName Then

                swFeat.Select2 False, -1
    
'               Delete current BOM (if one exists)
                swDraw.Extension.DeleteSelection2 swDeleteSelectionOptions_e.swDelete_Absorbed
    
'               New BOM preferences
                boolstatus = swModel.Extension.SelectByID2(swView.Name, "DRAWINGVIEW", 0, 0, 0, False, 0, Nothing, 0)
                AnchorType = swBOMConfigurationAnchorType_e.swBOMConfigurationAnchor_BottomLeft
                BomType = swBomType_e.swBomType_Indented
                Configuration = confname
                TableTemplate = "C:\...\Standard Module CAD Library\Pallet\Roller Straight\Sections\Library Generation Related\Master Drawings\BOM Temp.sldbomtbt"
                IndentedNumberingType = swNumberingType_e.swNumberingType_Detailed

'               Insert new BOM (if the old one was deleted)
                Set swBomAnn = swView.InsertBomTable4(True, 0.4, 0.3, AnchorType, BomType, Configuration, TableTemplate, False, IndentedNumberingType, False)
    
                    If InStr(confname, "-GA") Then
                        ExportBOM confname 'self explanatory
                    End If
    
                swModel.ClearSelection2 True
                swDraw.ForceRebuild

            End If
            Set swFeat = swFeat.GetNextFeature

        Wend

'   Run the above while loop without exporting BOM
    Set swFeat = swDraw.FirstFeature

        While Not swFeat Is Nothing

            If "BomFeat" = swFeat.GetTypeName Then

                swFeat.Select2 False, -1
    
                swDraw.Extension.DeleteSelection2 swDeleteSelectionOptions_e.swDelete_Absorbed
    
                BomType = swBomType_e.swBomType_TopLevelOnly
    
                Set swBomAnn = swView.InsertBomTable2(True, 0.4, 0.3, AnchorType, BomType, Configuration, TableTemplate)
    
                swModel.ClearSelection2 True
                swDraw.ForceRebuild

            End If
            Set swFeat = swFeat.GetNextFeature

        Wend

Next i

End Sub

Sub DeleteBalloons()

Dim swView      As SldWorks.View
Dim vsheets     As Variant
Dim Note        As Object
Dim Bool        As Boolean
Dim longstatus  As Long

Set swApp = Application.SldWorks
Set swDraw = swApp.ActiveDoc
vsheets = swDraw.GetViews

    For i = 0 To UBound(vsheets)
    
        If Not swDraw Is Nothing Then
            If swDraw.GetType = swDocumentTypes_e.swDocDRAWING Then
            Set swView = swDraw.GetFirstView '= drawing sheet
            Set swView = swView.GetNextView '= first real view
            
'           Loop through views
            While Not swView Is Nothing
                Set Note = swView.GetFirstNote
                
'               Loop through annotations
                While Not Note Is Nothing
                    If Note.IsBomBalloon Then
                        Dim nnavn As String
                        Dim booleanstatus As Boolean
                        nnavn = Note.GetName & "@" & swView.GetName2 'ID for balloon
                        boolstatus = swDraw.Extension.SelectByID2(nnavn & "@" & swView.GetName2, "NOTE", 0, 0, 0, True, 0, Nothing, 0)
                    End If
                    Set Note = Note.GetNext
                Wend
                
                Set swView = swView.GetNextView
            Wend
            
'           Delete annotations if they are balloons
            longstatus = swDraw.Extension.DeleteSelection2(SwConst.swDelete_Absorbed)
            End If
            
        End If
        
    Next i

End Sub

Sub AutoBalloon()

Dim boolstatus As Boolean
Dim longstatus As Long, longwarnings As Long
Dim vNotes As Variant
Dim autoballoonParams As Object

'Select exploded view
boolstatus = swDraw.ActivateSheet("Sheet2")
boolstatus = swDraw.ActivateView("EXP")
boolstatus = swDraw.Extension.SelectByID2("EXP", "DRAWINGVIEW", 0, 0, 0, False, 0, Nothing, 0)

'Choose autoballoon options
Set autoballoonParams = swDraw.CreateAutoBalloonOptions()
    autoballoonParams.Layout = 1
    autoballoonParams.ReverseDirection = False
    autoballoonParams.IgnoreMultiple = True
    autoballoonParams.InsertMagneticLine = False
    autoballoonParams.LeaderAttachmentToFaces = False
    autoballoonParams.Style = 1
    autoballoonParams.Size = 2
    autoballoonParams.EditBalloonOption = 1
    autoballoonParams.EditBalloons = 1
    autoballoonParams.UpperTextContent = 1
    autoballoonParams.UpperText = """"
    autoballoonParams.Layername = "DIMS & BALOONS"
    autoballoonParams.ItemNumberStart = 1
    autoballoonParams.ItemNumberIncrement = 1
    autoballoonParams.ItemOrder = 0

'Insert ballons and deselect view
vNotes = swDraw.AutoBalloon5(autoballoonParams)
swDraw.ClearSelection2 True

End Sub

Sub AutoScale(confname As String)
    
    Dim boolstatus  As Boolean
    Dim scaleMap    As Variant
    Dim FileLength  As Integer
    FileLength = Len(confname)
'   Array = "min width"-"max width", "min height"-"max height", "scale"
'   Use an asterisk * in a min/max field to negate it from being used
    
    If InStr(confname, "-GA") Then
    scaleMap = Array("1.8-3.2;*;1:7")
    Else
    scaleMap = Array("1.8-3.2;*;1:4")
    End If
    
    Set swApp = Application.SldWorks
    Dim swDraw As SldWorks.DrawingDoc

Try:
    
    On Error GoTo Catch
    
    Set swDraw = swApp.ActiveDoc
    
'   Rescale all views if a drawing is open otherwise show error
    If Not swDraw Is Nothing Then
        
'       Starts on sheet 2, rescale views accordingly then activate sheet 1
        RescaleViews swDraw, swDraw.GetCurrentSheet(), scaleMap
        boolstatus = swDraw.ActivateSheet("Sheet1")
        
'       Starting from sheet 1, rescale views accordingly then reactivate sheet 2
        RescaleViews swDraw, swDraw.GetCurrentSheet(), scaleMap
        boolstatus = swDraw.ActivateSheet("Sheet2")
        
    Else
        Err.Raise vbError, "", "Please open the drawing document"
    End If
    
    GoTo Finally
    
Catch:
    MsgBox Err.Description & " (" & Err.Number & ")", vbCritical
Finally:

End Sub

Sub RescaleViews(draw As SldWorks.DrawingDoc, sheet As SldWorks.sheet, scaleMap As Variant)
    
    Dim vViews As Variant
    vViews = GetSheetViews(draw, sheet)
    
    Dim i As Integer
    
    For i = 0 To UBound(vViews) 'Cycle all views on drawing
        
        Dim swView As SldWorks.View
        Set swView = vViews(i)
        Dim strView As String
        Dim confname As String
        strView = swView.GetName2
        conf = swView.ReferencedConfiguration
        
        If InStr(strView, "Detail View") Then 'skip detail views from using sheet scale
        GoTo Skip:
        End If
        
        If InStr(strView, "EXP") = 0 Then 'skip exploded view from using sheet scale
        swView.UseSheetScale = 1
        End If
        
        If InStr(confname, "-L20-") Or InStr(confname, "-L30-") Then 'use sheetscale on exploded view if it is over 1.5 meters
        swView.UseSheetScale = 1
        End If
        
        Dim width As Double
        Dim height As Double
        GetViewGeometrySize swView, width, height
        
        Dim j As Integer
        
        For j = 0 To UBound(scaleMap)
            
            Dim minWidth  As Double
            Dim maxWidth  As Double
            Dim minHeight As Double
            Dim maxHeight As Double
            Dim viewScale As Variant
            Dim bRet      As Boolean
            
'   Creates the declared parameters above from the scalemap we created earlier
            ExtractParameters CStr(scaleMap(j)), minWidth, maxWidth, minHeight, maxHeight, viewScale
            
            If width >= minWidth And width <= maxWidth And height >= minHeight And height <= maxHeight Then

                If Not BASE_VIEWS_ONLY Or swView.GetBaseView() Is Nothing Then
                    bRet = sheet.SetScale(viewScale(0), viewScale(1), False, False)
                Else
                End If
                
            Else
            End If
            
        Next
Skip:
    Next
    
    draw.EditRebuild
    
End Sub

Function GetSheetViews(draw As SldWorks.DrawingDoc, sheet As SldWorks.sheet) As Variant

    Dim vsheets As Variant
    vsheets = draw.GetViews()
    
    Dim i As Integer
    
    For i = 0 To UBound(vsheets) 'Cycle all sheets
    
        Dim vViews As Variant
        vViews = vsheets(i)
        
        Dim swSheetView As SldWorks.View
        Set swSheetView = vViews(0)
        
        If UCase(swSheetView.Name) = UCase(sheet.GetName()) Then
            
            If UBound(vViews) > 0 Then
                
                Dim swViews() As SldWorks.View
                
                ReDim swViews(UBound(vViews) - 1)
                
                Dim j As Integer
                
                For j = 1 To UBound(vViews) 'Cycle all views in current cycled sheet
                    Set swViews(j - 1) = vViews(j)
                Next
                
                GetSheetViews = swViews
                Exit Function
                
            End If
            
        End If
        
    Next
    
End Function

Sub GetViewGeometrySize(View As SldWorks.View, ByRef width As Double, ByRef height As Double)
    
    Dim borderWidth As Double
    borderWidth = GetViewBorderWidth(View)
    
    Dim vOutline    As Variant '               *SELF EXPLANATORY SUB*
    vOutline = View.GetOutline()
    
    Dim viewScale   As Double
    viewScale = View.ScaleRatio(1) / View.ScaleRatio(0)
    
    width = (vOutline(2) - vOutline(0) - borderWidth * 2) * viewScale
    height = (vOutline(3) - vOutline(1) - borderWidth * 2) * viewScale
    
End Sub

Function GetViewBorderWidth(View As SldWorks.View) As Double
    
    Const VIEW_BORDER_RATIO = 0.02
    
    Dim width As Double
    Dim height As Double
    
    View.sheet.GetSize width, height '         *SELF EXPLANATORY SUB*
    
    Dim minSize As Double
    
    If width < height Then
        minSize = width
    Else
        minSize = height
    End If
    
    GetViewBorderWidth = minSize * VIEW_BORDER_RATIO
    
End Function

Sub ExtractParameters(params As String, ByRef minWidth As Double, ByRef maxWidth As Double, ByRef minHeight As Double, ByRef maxHeight As Double, ByRef viewScale As Variant)

    Dim vParamsData As Variant
    vParamsData = Split(params, ";")
    
    ExtractSizeBounds CStr(vParamsData(0)), minWidth, maxWidth
    ExtractSizeBounds CStr(vParamsData(1)), minHeight, maxHeight
    
    Dim scaleData As Variant
    scaleData = Split(vParamsData(2), ":")
    
    Dim dViewScale(1) As Double
    dViewScale(0) = CDbl(Trim(scaleData(0)))
    dViewScale(1) = CDbl(Trim(scaleData(1)))
    
    viewScale = dViewScale
    
End Sub

Sub ExtractSizeBounds(boundParam As String, ByRef min As Double, ByRef max As Double)
    
    If Trim(boundParam) = "*" Then
        min = 0
        max = 1000000
    Else
        Dim minMax As Variant
        minMax = Split(boundParam, "-")
        min = CDbl(Trim(minMax(0)))
        max = CDbl(Trim(minMax(1)))
    End If
    
End Sub

Sub ExportBOM(confname As String)

    On Error GoTo ErrH:
    
    Dim swApp         As SldWorks.SldWorks
    Dim swModelDoc    As SldWorks.ModelDoc2
    Dim swSelMgr      As SldWorks.SelectionMgr
    Dim swTableAnn    As SldWorks.TableAnnotation
    Dim swBomFeature  As SldWorks.BomFeature
    Dim swAnn         As SldWorks.Annotation
    Dim vTableArr     As Variant
    Dim vTable        As Variant
    Dim retval        As Boolean
    Dim CSVFile       As String
                        
    Set swApp = Application.SldWorks
    Set swModelDoc = swApp.ActiveDoc
    Set swSelMgr = swModelDoc.SelectionManager

    TraverseFeatureTree
        
    ' Make sure a BOM is selected in the feature manager design tree
    Set swBomFeature = swSelMgr.GetSelectedObject5(1)
    
    
    ' Make sure a BOM is selected in the feature manager design tree
    If swBomFeature Is Nothing Then
        MsgBox "Please select a BOM to export"
        Exit Sub
    End If
    
    vTableArr = swBomFeature.GetTableAnnotations
        
    For Each vTable In vTableArr
        
        ' Got BOM as table annotation
        Set swTableAnn = vTable

    Next vTable
        
    ' Rename BOM with .csv file extension
    CSVFile = RenameBomToCSV(confname)
    
    retval = swTableAnn.SaveAsText(CSVFile, ",")
    
    ' Now change file extension to .xls and save
    SaveCSVAsXLS CSVFile
    
    ' Get rid of .csv file
    DeleteFile (CSVFile)
       
    ' Clean up
    Set swBomFeature = Nothing
    Set swModelDoc = Nothing
    Set swApp = Nothing
    
ErrH:
    
    If Err.Number = 0 Or Err.Number = 20 Then
    
        Resume Next
    Else
        ' Type mismatch
        If swBomFeature Is Nothing Then
            MsgBox "Please select a BOM from the Feature Manager Tree"
            Exit Sub
        Else
            MsgBox Err.Number & " " & Err.Description
        End If
    End If
    
End Sub

Sub TraverseFeatureTree()
    
    Dim swApp As SldWorks.SldWorks
    Dim swModelDoc As SldWorks.ModelDoc2
    Dim swFeature As SldWorks.Feature
    Dim ModelDocType As Long
    Dim FeatureName As String
    
    
    ' Connect to SW
    Set swApp = Application.SldWorks
    
    ' Get active document
    Set swModelDoc = swApp.ActiveDoc
    
    ' Clear anything selected
    swModelDoc.ClearSelection
    
    ' Get document type
    ModelDocType = swModelDoc.GetType
    
    ' Get first feature in feature tree
    Set swFeature = swModelDoc.FirstFeature
    
        ' Start traversal
        While Not swFeature Is Nothing

            FeatureName = swFeature.Name
                    
                If Left(FeatureName, 17) = "Bill of Materials" Then
            
                    ' Select the BOM
                    swFeature.Select True
                    
                    ' Exit early
                    Exit Sub
                
                End If
        
            ' Get next feature
            Set swFeature = swFeature.GetNextFeature
        
        Wend
    
End Sub

Function RenameBomToCSV(confname As String) As String
      
    Dim swApp         As SldWorks.SldWorks
    Dim swModelDoc    As SldWorks.ModelDoc2
    Dim GetPath       As String
    Dim Arr()         As String
    Dim Num           As Integer
    
    'Clear string
    RenameBomToCSV = ""
    
    Set swApp = Application.SldWorks
    Set swModelDoc = swApp.ActiveDoc
    
    'Get full path of active document
    GetPath = swModelDoc.GetPathName
    
    ' C:\...\Standard Module CAD Library\Pallet\Roller Straight\Sections\Library Generation Related\Master Drawings\**drawing name.slddrw**
    '
    ' 0    1                 2               3          4           5                 6                   7                   8
    '
    Arr = Split(GetPath, "\")
    i = Len(Arr(8)) - 7
    j = Len(Arr(7)) + 1
    
    GetPath = VBA.Left(GetPath, Len(GetPath) - 7) 'Take off solidworks file extension
    GetPath = VBA.Left(GetPath, Len(GetPath) - i) 'Take off current configuration ID
    GetPath = VBA.Left(GetPath, Len(GetPath) - j) 'Take off file extension and replace with desired
    
    'Add csv file extension
    GetPath = GetPath & "Macro-Generated Drawings\" & confname & ".csv"
    
    RenameBomToCSV = GetPath
    
    'Clean up
    Set swModelDoc = Nothing
    Set swApp = Nothing

End Function

' Pass in the CSV file
Sub SaveCSVAsXLS(WhichDoc As String)
    
    Dim xlApp As Excel.Application
    Dim xlWB  As Excel.Workbook
    Dim FileToKill As String
    
    ' If there is an existing file it will get deleted
    FileToKill = VBA.Left(WhichDoc, Len(WhichDoc) - 3) & "xls"
 
      If Dir(FileToKill) <> "" Then

        Kill FileToKill
        
        Set xlApp = CreateObject("Excel.Application")
    
        xlApp.Visible = False
        
        ' Open the CSV file
        Set xlWB = xlApp.Workbooks.Open(WhichDoc)
        
        ' Save as xls
        xlWB.SaveAs VBA.Left(WhichDoc, Len(WhichDoc) - 3) & "xls", 56
        
        ' Show the xls file
        xlApp.Visible = True
        
        ' Close the BOM
        xlApp.Workbooks.Close
        
        ' Close Excel
        xlApp.Quit
        
    Else
        
        Set xlApp = CreateObject("Excel.Application")
        xlApp.Visible = False
        Set xlWB = xlApp.Workbooks.Open(WhichDoc)
        xlWB.SaveAs VBA.Left(WhichDoc, Len(WhichDoc) - 3) & "xls", 56
        xlApp.Visible = True
        xlApp.Workbooks.Close
        xlApp.Quit
    
    End If
    
End Sub

Sub DeleteFile(DeleteWhichFile As String)

    Kill DeleteWhichFile

End Sub

Sub Core()
main
End Sub
