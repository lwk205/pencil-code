; $Id: pc_read_var.pro,v 1.7 2004-04-09 14:30:25 mcmillan Exp $
;
;   Read var.dat, or other VAR file
;
;  Author: Tony Mee (A.J.Mee@ncl.ac.uk)
;  $Date: 2004-04-09 14:30:25 $
;  $Revision: 1.7 $
;
;  27-nov-02/tony: coded 
;
;  
pro pc_read_var,t=t,x=x,y=y,z=z,dx=dx,dy=dy,dz=dz,deltay=deltay, all=all, $
                uum=uum, lnrhom=lnrhom, ss=ss, aa=aa, lncc=lncc, ee=ee, ff=ff, $
                uud=uud, lnrhod=lnrhod, $
                object=object, varfile=varfile, ASSOCIATE=ASSOCIATE, $
                datadir=datadir,proc=proc,PRINT=PRINT,QUIET=QUIET,HELP=HELP
  COMMON pc_precision, zero, one
; If no meaningful parameters are given show some help!
  IF ( keyword_set(HELP) ) THEN BEGIN
    print, "Usage: "
    print, ""
    print, "pc_read_var, t=t, x=x, y=y, z=z, dx=dx, dy=dy, dz=dz, deltay=deltay, $                     "
    print, "             uum=uum, lnrhom=lnrhom, ss=ss, aa=aa, lncc=lncc, ee=ee, ff=ff, $                  "
    print, "             object=object, $                                                              "
    print, "             varfile=varfile, datadir=datadir, proc=proc, $                                "
    print, "             /PRINT, /QUIET, /HELP                                                         "
    print, "                                                                                           "
    print, " Returns field from a snapshot (var) file generated by a Pencil-Code run. For a specific   "
    print, " processor.  Returns zeros and empty in all variables on failure.                          "
    print, "                                                                                           "
    print, "  datadir: specify the root data directory. Default is './data'                    [string]"
    print, "     proc: specify a processor to get the data from. Default is 0                 [integer]"
    print, "  varfile: specify an alternative name for the var file, default is 'var.dat'      [string]"
    print, "                                                                                           "
    print, "        t: array of x mesh point positions in code length units             [precision(mx)]"
    print, "        x: array of x mesh point positions in code length units             [precision(mx)]"
    print, "        y: array of y mesh point positions in code length units             [precision(my)]"
    print, "        z: array of z mesh point positions in code length units             [precision(mz)]"
    print, "       dx: x mesh spacing in code length units                                  [precision]"
    print, "       dy: y mesh spacing in code length units                                  [precision]"
    print, "       dz: z mesh spacing in code length units                                  [precision]"
    print, "       uum: velocity field (vector) in code units                    [precision(mx,my,mz,3)]"
    print, "    lnrhom: density field (scalar) in code units                       [precision(mx,my,mz)]"
    print, "       ss: entropy field (scalar) in code units                       [precision(mx,my,mz)]"
    print, "       aa: magnetic vector potential (vector) in code units         [precision(mx,my,mz,3)]"
    print, "     lncc: passive scalar field (scalar) in code units                [precision(mx,my,mz)]"
    print, "       ee: radiation ??                                               [precision(mx,my,mz)]"
    print, "       ff: radiation ??                                               [precision(mx,my,mz)]"
    print, ""
    print, "   object: optional structure in which to return all the above as tags          [structure] "
    print, ""
    print, "   /PRINT: instruction to print all variables to standard output                            "
    print, "   /QUIET: instruction not to print any 'helpful' information                               "
    print, "    /HELP: display this usage information, and exit                                         "
    return
  ENDIF
IF keyword_set(HELP) THEN PRINT, "USING EXPERIMENTALN OPTION ASSOC!!"
; Default data directory

default, datadir, 'data'
default,proc,0
default,varfile,'var.dat'

; Get necessary dimensions, inheriting QUIET
pc_read_dim,mx=mx,my=my,mz=mz,mvar=mvar,precision=precision,datadir=datadir,proc=proc,QUIET=QUIET 
; and check pc_precision is set!                                                    
pc_set_precision,precision=precision
pc_read_param,object=params,datadir=datadir,QUIET=QUIET 

;
; Initialize / set default returns for ALL variables
;

t=zero
x=fltarr(mx)*one & y=fltarr(my)*one & z=fltarr(mz)*one
dx=zero &  dy=zero &  dz=zero & deltay=zero
;uum=uum
;lnrhom=lnrhom
;ss=ss,aa=aa,lncc=lncc,ee=ee,ff=ff

iuum=0    
ilnrhom=0    
iss=0  
iaa=0
ie=0
ilncc=0 
iuud=0 
ilnrhod=0 
if (params.lhydro)        then iuum=1
if (params.ldensity)      then ilnrhom=1    
if (params.lentropy)      then iss=1  
if (params.lmagnetic)     then iaa=1
if (params.lradiation)    then ie=1 
if (params.lpscalar)      then ilncc=1 
if (params.ldustvelocity) then iuud=1
if (params.ldustdensity)  then ilnrhod=1    


if (params.lhydro)        then uum     = fltarr(mx,my,mz,3)*one
if (params.ldensity)      then lnrhom = fltarr(mx,my,mz  )*one
if (params.lentropy)      then ss     = fltarr(mx,my,mz  )*one
if (params.lmagnetic)     then aa     = fltarr(mx,my,mz,3)*one
if (params.lradiation)    then ff     = fltarr(mx,my,mz,3)*one
if (params.lradiation)    then ee     = fltarr(mx,my,mz  )*one
if (params.lpscalar )     then lncc   = fltarr(mx,my,mz  )*one
if (params.ldustvelocity) then uud    = fltarr(mx,my,mz,3)*one
if (params.ldustdensity)  then lnrhod = fltarr(mx,my,mz  )*one

; Get a unit number
GET_LUN, file

; Build the full path and filename
filename=datadir+'/proc'+str(proc)+'/'+varfile 

; Check for existance and read the data
dummy=findfile(filename, COUNT=cgrid)
if (cgrid gt 0) then begin
  IF ( not keyword_set(QUIET) ) THEN print, 'Reading ' + filename + '...'
  ;
  ;  Read data
  ;
  openr,file, filename, /F77
                     ;
  if iuum ne 0 and ilnrhom ne 0 and iss ne 0 and iaa ne 0 then begin
      if ( not keyword_set(QUIET) ) then print,'MHD with entropy'
      if not keyword_set(ASSOCIATE) then readu,file,uum,lnrhom,ss,aa
  end else if iuum ne 0 and ilnrhom ne 0 and iss eq 0 and iaa ne 0 $ 
           and iuud eq 0 and ilnrhod eq 0 then begin
      if ( not keyword_set(QUIET) ) then print,'hydro without entropy, but with magnetic field'
      if not keyword_set(ASSOCIATE) then readu,file,uum,lnrhom,aa
  end else if iuum ne 0 and ilnrhom ne 0 and iss ne 0 and ie ne 0 $
           and iuud eq 0 and ilnrhod eq 0 then begin
      if ( not keyword_set(QUIET) ) then print,'hydro with entropy, density and radiation'
      if not keyword_set(ASSOCIATE) then readu,file,uum,lnrhom,ss,ee,ff
  end else if iuum ne 0 and ilnrhom ne 0 and iss ne 0 and iaa eq 0 $
           and iuud eq 0 and ilnrhod eq 0 then begin
      if ( not keyword_set(QUIET) ) then print,'hydro with entropy, but no magnetic field'
      if not keyword_set(ASSOCIATE) then readu,file,uum,lnrhom,ss
      if keyword_set(ASSOCIATE) then begin
          all=assoc(file,fltarr(mx,my,mz,mvar)*one,4)
      endif
  end else if iuum ne 0 and ilnrhom ne 0 and ilncc ne 0 and iaa eq 0 then begin
      if ( not keyword_set(QUIET) ) then print,'hydro with entropy, but no magnetic field'
      if not keyword_set(ASSOCIATE) then readu,file,uum,lnrhom,lncc
  end else if iuum ne 0 and ilnrhom ne 0 and iss eq 0 and iaa eq 0 then begin
      if ( not keyword_set(QUIET) ) then print,'hydro with no entropy and no magnetic field'
      if not keyword_set(ASSOCIATE) then readu,file,uum,lnrhom
  end else if iuum ne 0 and ilnrhom eq 0 and iss eq 0 and iaa eq 0 then begin
      if ( not keyword_set(QUIET) ) then print,'just velocity (Burgers)'
      if not keyword_set(ASSOCIATE) then readu,file,uum
  end else if iuum eq 0 and ilnrhom eq 0 and iss eq 0 and iaa ne 0 then begin
      if ( not keyword_set(QUIET) ) then print,'just magnetic fparams.ield (kinematic)'
      if not keyword_set(ASSOCIATE) then readu,file,aa
  end else if iuum eq 0 and ilnrhom eq 0 and iss eq 0 and iaa eq 0 and ilncc ne 0 then begin
      if ( not keyword_set(QUIET) ) then print,'just passive scalar (no field nor hydro)'
      if not keyword_set(ASSOCIATE) then readu,file,lncc
  end else if iuum eq 0 and ilnrhom ne 0 and iss eq 0 and iaa eq 0 then begin
      if ( not keyword_set(QUIET) ) then print,'just density (probably just good for tests)'
      if not keyword_set(ASSOCIATE) then readu,file,lnrhom
  end else if iuum eq 0 and ilnrhom eq 0 and iss eq 0 and iaa eq 0 and ie ne 0 then begin
      if ( not keyword_set(QUIET) ) then print,'just radiation'
      if not keyword_set(ASSOCIATE) then readu,file,ee,ff
  end else if iuum ne 0 and ilnrhom ne 0 and iss ne 0 and iuud ne 0 $
           and ilnrhod ne 0 then begin
      if ( not keyword_set(QUIET) ) then $
          print,'hydro with entropy, density, dustvelocity and dustdensity'
      if not keyword_set(ASSOCIATE) then readu,file,uum,lnrhom,ss,uud,lnrhod
  end else begin
      if ( not keyword_set(QUIET) ) then print,'not prepared...'
  end
                                ;
  if (params.lshear) then begin
      readu,file, t, x, y, z, dx, dy, dz, deltay
  end else begin
      readu,file, t, x, y, z, dx, dy, dz
  end

  if not keyword_set(ASSOCIATE) then begin
    close,file
    FREE_LUN,file
  endif

 end else begin
  message, 'ERROR: cannot find file '+ filename
end

; Build structure of all the variables
object = CREATE_STRUCT(name=filename,['t','x','y','z','dx','dy','dz'],t,x,y,z,dx,dy,dz)

; If requested print a summary
if keyword_set(PRINT) then begin
    print, 'For ',proc,' calculation domain:'
;
;  Summarise data
;
xyz = ['x', 'y', 'z']
fmt = '(A,4G15.6)'
print, '  var            minval         maxval          mean           rms'
    if (params.lhydro) then $
      for j=0,2 do $
      print, FORMAT=fmt, 'uum_'+xyz[j]+'   =', $
      minmax(uum(*,*,*,j)), mean(uum(*,*,*,j),/DOUBLE), rms(uum(*,*,*,j),/DOUBLE)
    if (params.ldensity) then $
      print, FORMAT=fmt, 'lnrhom  =', $
      minmax(lnrhom), mean(lnrhom,/DOUBLE), rms(lnrhom,/DOUBLE)
    if (params.lentropy) then $
      print, FORMAT=fmt, 'ss     =', $
      minmax(ss), mean(ss,/DOUBLE), rms(ss,/DOUBLE)
    if (params.lpscalar) then $
      print, FORMAT=fmt, 'lncc   =', $
      minmax(lncc), mean(lncc,/DOUBLE), rms(lncc,/DOUBLE)
    if (params.lradiation) then $
      for j=0,2 do $
      print, FORMAT=fmt, 'ff_'+xyz[j]+'   =', $
      minmax(ff(*,*,*,j)), mean(ff(*,*,*,j),/DOUBLE), rms(ff(*,*,*,j),/DOUBLE)
    if (params.lradiation) then $
      print, FORMAT=fmt, 'ee     =', $
      minmax(ee), mean(ee,/DOUBLE), rms(ee,/DOUBLE)
    if (params.lmagnetic) then begin
        for j=0,2 do $
          print, FORMAT=fmt, 'aa_'+xyz[j]+'   =', $
          minmax(aa(*,*,*,j)), mean(aa(*,*,*,j),/DOUBLE), rms(aa(*,*,*,j),/DOUBLE)
        if (cpar gt 0) then begin
            eta=par2.eta
        end
    end  
    print, '             t = ', t
endif


end
