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
;GFIT MODEL COMPONENT
;
;NAME:
;  qsfit_comp_ironoptical
;
;COMPONENT DESCRIPTION:
;  The iron template at optical wavelengths from Veron-Cetty et
;  al. 2004.  The template is generated by summing a Gaussian profile
;  for each line listed in tables A.1 and A.2 of Veron-Cetty et
;  al. (2004), excluding the hydrogen Balmer lines.  The "broad" and
;  "narrow" emission lines are kept separated, each with their own
;  parameters.  We considered only the William Herschel Telescope
;  (WHT) intensities.
;
;PARAMETERS:
;  NORM_BR, NORM_NA (units: [X*Y])
;    Total flux in the iron broad and narrow complex respectively.
;
;  FWHM_BR, FWHM_NA (units: km s^-1)
;    FWHM of emission line for the broad and narrow complex
;    respectively. This parameter is used to broaden the iron template
;    by convolution with a Gaussian kernel.
;
;OPTIONS:
;  NONE
;
;REFERENCES:
;  Veron-Cetty, Joly and Veron, 2004, A&A, 417, 515
;  http://adsabs.harvard.edu/abs/2004A%26A...417..515V
;


PRO qsfit_comp_ironoptical_prepare, templ_br, templ_na
  COMPILE_OPT IDL2
  ON_ERROR, !glib.on_error

  gprint, 'Preparation of Veron-Cetty et al. (2004) optical iron template...'

  ;;Check input files are available
  path = FILE_DIRNAME(ROUTINE_FILEPATH('qsfit_comp_ironoptical_prepare')) + PATH_SEP()
  path += 'VC2004' + PATH_SEP()
  IF (~gfexists(path + 'TabA1')) THEN $
     MESSAGE, 'Could not found Veron-Cetty et al. (2004) template files in directory: ' + path

  ;;Read input files
  template = {line: '', transition: '', ul:0., wavelength: 0., aat:0., wht: 0.}
  broad  = greadtexttable(path + 'TabA1', /drop, template=template)
  narrow = greadtexttable(path + 'TabA2', /drop, template=template)
  broad  = broad [WHERE(FINITE(broad.wht))]
  narrow = narrow[WHERE(FINITE(narrow.wht))]

  ;;Drop Balmer lines (they are accounted for in the main QSFIT code)
  broad  = broad [WHERE(STRMID(broad.line , 0, 2) NE 'H$')]
  narrow = narrow[WHERE(STRMID(narrow.line, 0, 2) NE 'H$')]

  ;;Pre-compute the broadened teplates
  ;;(see Sect. 3 of Vestergaard&Wilkes 2001)

  ;;Grid of FWHM values
  fwhm_na = gloggen(1.e2, 1.e3, 300)
  fwhm_br = gloggen(1.e3, 2.e4, 300)

  ;;Grid of wavelengths
  ref_x = ggen(3300, 7400, 2000)

  ;;Prepare return structure
  templ_br = {  x:   ref_x,                          $
                y:   FLTARR(gn(ref_x), gn(fwhm_br)), $
                fwhm: fwhm_br                        $
             }
  templ_na = {  x:   ref_x,                          $
                y:   FLTARR(gn(ref_x), gn(fwhm_na)), $
                fwhm: fwhm_na                        $
             }

  ;;Generate templates
  FOR i=0, gn(fwhm_br)-1 DO BEGIN
     templ_br.y[*,i] = templ_br.x * 0.
     FOR j=0, gn(broad)-1 DO BEGIN
        ;;Compute sigma of Gaussian profile in units of c
        sigma = fwhm_br[i] / 2.35 / 3.e5 * broad[j].wavelength
        templ_br.y[*,i] += broad[j].wht * ggauss(ref_x, broad[j].wavelength, sigma)
     ENDFOR
     templ_br.y[*,i] /= INT_TABULATED(templ_br.x, templ_br.y[*,i])
  ENDFOR

  FOR i=0, gn(fwhm_na)-1 DO BEGIN
     templ_na.y[*,i] = templ_na.x * 0.
     FOR j=0, gn(narrow)-1 DO BEGIN
        ;;Compute sigma of Gaussian profile in units of c
        sigma = fwhm_na[i] / 2.35 / 3.e5 * narrow[j].wavelength
        templ_na.y[*,i] += narrow[j].wht * ggauss(ref_x, narrow[j].wavelength, sigma)
     ENDFOR
     templ_na.y[*,i] /= INT_TABULATED(templ_na.x, templ_na.y[*,i])
  ENDFOR


  IF (0) THEN BEGIN
     ggp_clear
     ggp_cmd, xtit='Wavelength [AA]', ytit='Flux density [arb. units]'
     dummy = MIN(ABS(templ_br.fwhm - 3000), i3000)
     FOREACH i, [0, i3000, gn(templ_br.fwhm)-1] DO $
        ggp_data, templ_br.x, templ_br.y[*,i], plot='w l t "FWHM=' + gn2s(templ_br.fwhm[i]) + ' km/s"'
     ggp

     ggp_clear
     ggp_cmd, xtit='Wavelength [AA]', ytit='Flux density [arb. units]'
     dummy = MIN(ABS(templ_na.fwhm - 300), i300)
     FOREACH i, [0, i3000, gn(templ_na.fwhm)-1] DO $
        ggp_data, templ_na.x, templ_na.y[*,i], plot='w l t "FWHM=' + gn2s(templ_na.fwhm[i]) + ' km/s"'
     ggp
  ENDIF
END


PRO qsfit_comp_ironoptical_init, comp
  COMPILE_OPT IDL2
  ON_ERROR, !glib.on_error
  COMMON COM_qsfit_comp_ironoptical, templ_br, templ_na, cur_br, cur_na

  path = FILE_DIRNAME(ROUTINE_FILEPATH('qsfit_comp_ironoptical_init')) + PATH_SEP()
  IF (gn(templ) EQ 0) THEN BEGIN
     file = path + 'qsfit_comp_ironoptical.dat'
     IF (gfexists(file)) THEN $
        RESTORE, file $
     ELSE BEGIN
        qsfit_comp_ironoptical_prepare, templ_br, templ_na
        SAVE, file=file, /compress, templ_br, templ_na
     ENDELSE
  ENDIF
  cur_br = []
  cur_na = []

  comp.norm_br.val       = 100
  comp.norm_br.limits[0] = 0

  comp.norm_na.val       = 100
  comp.norm_na.limits[0] = 0

  comp.fwhm_br.val    = 3000
  comp.fwhm_br.limits = gminmax(templ_br.fwhm)
  comp.fwhm_br.step   = templ_br.fwhm[1] - templ_br.fwhm[0]
  
  comp.fwhm_na.val    = 500
  comp.fwhm_na.limits = gminmax(templ_na.fwhm)
  comp.fwhm_na.step   = templ_na.fwhm[1] - templ_na.fwhm[0]
END


FUNCTION qsfit_comp_ironoptical, x, norm_br, fwhm_br, norm_na, fwhm_na
  COMPILE_OPT IDL2
  ON_ERROR, !glib.on_error
  COMMON COM_qsfit_comp_ironoptical

  ;;Initialize templates using current X values
  IF (gn(cur_br) EQ 0) THEN BEGIN
     gprint, 'Interpolation of Veron-Cetty (2004) optical iron template...'

     cur_br = FLTARR(gn(x), gn(templ_br.fwhm))
     cur_na = FLTARR(gn(x), gn(templ_na.fwhm))

     FOR i=0, gn(templ_br.fwhm)-1 DO cur_br[*,i] = INTERPOL(REFORM(templ_br.y[*,i]), templ_br.x, x)
     FOR i=0, gn(templ_na.fwhm)-1 DO cur_na[*,i] = INTERPOL(REFORM(templ_na.y[*,i]), templ_na.x, x)
     cur_br = (cur_br > 0) 
     cur_na = (cur_na > 0) 
  ENDIF


  ;;Search for the template with the closest value of FWHM
  dummy = MIN(ABS(fwhm_br - templ_br.fwhm), ibr)
  dummy = MIN(ABS(fwhm_na - templ_na.fwhm), ina)

  RETURN, norm_br * REFORM(cur_br[*, ibr]) + $
          norm_na * REFORM(cur_na[*, ina])
END




