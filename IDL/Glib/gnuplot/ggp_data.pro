; *******************************************************************
; Copyright (C) 2016 Giorgio Calderone
;
; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public icense
; as published by the Free Software Foundation; either version 2
; of the License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program. If not, see <http://www.gnu.org/licenses/>.
;
; *******************************************************************

;=====================================================================
;NAME:
;  ggp_data
;
;PURPOSE:
;  Insert a new data set into current GGP buffer.
;
;DESCRIPTION:
;  This procedure convert data from IDL form into a form suitable to
;  be passed to gnuplot, and store the data into the GGP buffer.  The
;  conversion occurs through the ggp_prepare_data function. 
;
;  Each data set inserted through ggp_data has an associated name to
;  distinguish it from the others.  Such name can be either given with
;  the NAME= keyword or be be automatically generated by ggp_data.  In
;  the latter case the data set name can be retrieved with the
;  GETNAME= keyword.
;
;PARAMETERS:  
;  P0, P1, ..., P19 (input, up to 20 scalar(s) or array(s) of any type
;  except structure)
;    Input data to be stored in GGP internal buffer
;
;  /CLEAR  (keyword)
;    Call ggp_clear before any operation.
;
;  PLOT= (optional input, scalar string)
;    Plotting options (i.e. the arguments to the "plot" and "splot"
;    gnuplot commands) for the data set being inserted.  This string
;    is prepended with the data set name and passed to gpp_plot.  If
;    the PLOT= keyword is not given the call to ggp_plot should be
;    made explicitly by the user, otherwise the data set won't be
;    plotted.
;
;  BASENAME= (optional input, scalar string)
;    Provide a base name for the data set.  An automatic suffix will
;    be added to ensure the data set name is unique among all the
;    available data sets.  If both BASENAME= and NAME= are not given,
;    'idl' + (integer suffix) will be used.
;
;  NAME= (optional input, scalar string)
;    Provide a name for the data set.  If not given a default name
;    will be used (see the BASENAME= parameter).
;
;  GETNAME= (output, scalar string)
;    Return the data set name, either the one given with NAME= or the
;    autogenerated name.
;
;EXAMPLES:
;  d = [1,2]
;  ggp_clear
;  ggp_data, d, d, getname=name
;  ggp_plot, name + 'w lines'
;  ggp
;
;  The ggp_clear, ggp_data and ggp_plot calls may be joined in a
;  single call:
;
;  d = [1,2]
;  ggp_data, /clear, d, d, plot='w lines'
;  ggp
;
PRO ggp_data $
   , p0  , p1,  p2,  p3,  p4,  p5,  p6,  p7,  p8,  p9  $
   , p10, p11, p12, p13, p14, p15, p16, p17, p18, p19  $
   , CLEAR=clear, PLOT=plot, BASENAME=basename, NAME=iname, GETNAME=name
  COMPILE_OPT IDL2
  ON_ERROR, !glib.on_error
  COMMON COM_GGP

  IF (KEYWORD_SET(clear)) THEN ggp_clear

  dataset = []
  FOR ipar=0, N_PARAMS()-1 DO BEGIN
     dummy = EXECUTE('par = p'+gn2s(ipar))
     par = DOUBLE(par)
     dataset = CREATE_STRUCT(dataset, 'd' + gn2s(ipar), REFORM(par))
  ENDFOR
  
  dataset = ggp_prepare_data(dataset, keybreak=keybreak)

  IF (~KEYWORD_SET(basename)) THEN $
     basename = 'idl'
  name = STRTRIM(STRING(basename[0]), 2) + gn2s(N_TAGS(ggp_data))

  IF (KEYWORD_SET(iname)) THEN $
     name = STRTRIM(STRING(iname[0]), 2)
  ggp_data = CREATE_STRUCT(ggp_data, name, dataset)

  name = '$' + STRLOWCASE(name) + ' '

  IF (KEYWORD_SET(plot)) THEN $
     FOR i=0, gn(plot)-1 DO $
        ggp_plot, name + STRING(plot[i])
END