'===============================================================================
'# BROWSEFORFOLDERS : Returns the selected folder

function BrowseForFolders (initialdir as string, wincapt as string) as string
dim bff_form as qform
with bff_form
.height = 400
.center
.caption = wincapt
'.delbordericons 2
end with

dim bff_tree as qdirtree
with bff_tree
.parent = bff_form
.align = 5
end with
if bff_form.caption = "" then bff_form.caption = "Select folder"
if direxists(initialdir) then
bff_tree.directory = initialdir
else
bff_tree.directory = curdir$
end if
bff_form.showmodal
result = bff_tree.directory
end function

