'=======================================================
' Type Objet
' Classe QTabControlEx version 1.0
'=======================================================

Type QTabControlEx Extends QTabControl
  Public:
  TabCount as integer Property Set SetTabCount

  '============================================
  ' proprieté nombre onglets
  '============================================
  Property Set SetTabCount(count as integer)
  'read only
End Property

Private:
'============================================
' Méthode suppression
'============================================
Sub Delete(n as integer,sender as qtabcontrol)
  sender.DelTabs n
End Sub

Public:
'============================================
' Méthode suppression onglet
'============================================
Sub DeleteTabs(index as integer)
  if this.TabCount>0 then
    this.delete index,this
    this.TabCount=this.TabCount-1
  end if
End Sub

'============================================
' Méthode ajout onglet
'============================================
Sub Add(s as string)
  super.AddTabs s
End Sub

'============================================
' Méthode ajout onglet redefini
'============================================
Subi AddTabs(...)
dim i as integer

for i=1 to ParamStrCount
  this.Add ParamStr$(i)
  this.TabCount=this.TabCount+1
next i
End Subi

'============================================
' Méthode insertion onglet redefini
'============================================
Sub InsertTab(index as integer,s as string)
  super.InsertTab index,s
  this.TabCount=this.TabCount+1
End Sub

'============================================
' Méthode suppression total des onglets
'============================================
Sub Clear
  dim i as integer

  for i=0 to this.TabCount-1
    this.DeleteTabs 0
  next i
  this.TabCount=0
End Sub

Constructor
TabCount=0
End Constructor
End Type


