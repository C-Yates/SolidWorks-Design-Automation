# SolidWorks-Design-Automation
Solidworks drawings - automation macro (see README)

The full c:\... destination has been omitted in the published code but the code itself can be repurposed by people looking to start creating macros using the Visual Basic for Applications (VBA) language.

This script in particular will likely not be a copy/paste solution for anyone looking to automate and there are ample comments to explain processes in the file, but I will outline the functionality as follows:-

- A solidworks drawing is open on the system allowing the script to be run.

- Run a series of process loops allowing iteration over each configuration of a model within the drawing sheet.

- Various processes are carried out during iteration including but not limited to; deletion of existing bill of materials (BOM) on assembly drawings and reinserting the   relevant one, balloon insertion, scaling, creation of flat-pattern and handling of flat model generation at a model level.

- Error handling is used throughout to filter irrelevant or incompatible files that don't suit my criteria (see comments in code).
