*&---------------------------------------------------------------------*
*& Modulpool         /MSH/STOER_MAINT
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*


INCLUDE /msh/stoer_maint_top                    .    " global Data

* Externe Includes
INCLUDE ljs01pt1.
INCLUDE mjv00tc9.
INCLUDE mj_trtyp.
INCLUDE mj000tal.
INCLUDE mj000fbc.
INCLUDE mjy00f03 .

* Log-Handling
INCLUDE /msh/camp_framework_logc.
INCLUDE /msh/camp_framework_logf.

* Programmhandling
INCLUDE /msh/stoer_maint_f01.             " Ablaufroutinen 1
INCLUDE /msh/stoer_maint_pbo.             " PBO-Routinen
INCLUDE /msh/stoer_maint_pai.             " PAI-Routinen
INCLUDE /msh/stoer_maint_p01.             " Lokale Klassendefinitionen 1
INCLUDE /msh/stoer_maint_f02.
INCLUDE /msh/stoer_maint_f03.
