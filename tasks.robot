*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    @{orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Get Preview Image    ${order}[Order number]
        Order bot and Get Receipt    ${order}[Order number]
        Order another Robot
    END
    Archive Output PDFs    ${OUTPUT_DIR}${/}Receipts
    [Teardown]    Close RoboSpare Browse


*** Keywords ***
Open the robot order website
    Open Chrome Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    Download
    ...    https://robotsparebinindustries.com/orders.csv
    ...    %{ROBOT_ROOT}${/}orders.csv
    ...    overwrite=${TRUE}
    @{orders}=    Read table from CSV    %{ROBOT_ROOT}${/}orders.csv
    RETURN    ${orders}

Close the annoying modal
    Click Button When Visible    alias:OK Button

Fill the form
    [Arguments]    ${order}
    Select From List By Index    alias:Head Box    ${order}[Head]
    ${element}=
    ...    Execute Javascript
    ...    return window.document.getElementById('id-body-${order}[Body]');
    Select Checkbox    ${element}
    Input Text    alias:Legs Input    ${order}[Legs]
    Input Text    alias:Shipping Address Input    ${order}[Address]

Get Preview Image
    [Arguments]    ${orderNumber}
    Click Button When Visible    alias:Preview Button
    Wait Until Element Is Visible    alias:Robot Preview Image
    Wait Until Element Is Visible    alias:BodyPreview
    Wait Until Element Is Visible    alias:HeadPreview
    Wait Until Element Is Visible    alias:LegsPreview
    Screenshot
    ...    alias:Robot Preview Image
    ...    ${OUTPUT_DIR}${/}RobotPreview-${orderNumber}.png

Order bot and Get Receipt
    [Arguments]    ${orderNumber}
    Click Button When Visible    alias:Order Button
    ${elementVisible}=    Is Element Visible    alias:Receipt DIV
    WHILE    not ${elementVisible}    limit=50
        Click Button When Visible    alias:Order Button
        ${elementVisible}=    Is Element Visible    alias:Receipt DIV
    END
    Wait Until Element Is Visible    alias:Receipt DIV
    ${Receipt}=    Get Element Attribute    alias:Receipt DIV    outerHTML
    Html To Pdf    ${Receipt}    ${OUTPUT_DIR}${/}Receipts${/}receipt-${orderNumber}.pdf
    Embed the robot screenshot to the receipt PDF file
    ...    ${OUTPUT_DIR}${/}RobotPreview-${orderNumber}.png
    ...    ${OUTPUT_DIR}${/}Receipts${/}receipt-${orderNumber}.pdf

Order another Robot
    Click Button When Visible    alias:Orderanother Button

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List
    ...    ${screenshot}
    Open Pdf    ${pdf}
    Add Files To Pdf
    ...    ${files}
    ...    ${pdf}
    ...    append:True
    Close Pdf    ${pdf}
    Remove File    ${screenshot}

Archive Output PDFs
    [Arguments]    ${folder}
    Archive Folder With Zip    ${folder}    ${OUTPUT_DIR}${/}receipts.zip

Close RoboSpare Browse
    Close Browser
