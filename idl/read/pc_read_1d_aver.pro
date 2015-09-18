;
; $Id: pc_read_1d_aver.pro 23239 2015-03-26 20:29:51Z mreinhardt@nordita.org $
;
;  Read 1d-averages from file.
;
pro pc_read_1d_aver, dir, object=object, varfile=varfile, datadir=datadir, $
    monotone=monotone, quiet=quiet
COMPILE_OPT IDL2,HIDDEN
COMMON pc_precision, zero, one
;
;  Default data directory.
;
if (not keyword_set(datadir)) then datadir=pc_get_datadir()

if (dir eq 'z') then begin
  ndir = dim.nz
  avdirs = 'xy'
end else if (dir eq 'y') then begin
  ndir = dim.ny
  avdirs = 'xz'
end else if (dir eq 'x') then begin
  ndir = dim.nx
  avdirs = 'yz'
end else begin
  message, 'ERROR: unknown direction "'+dir+'"!'
end

default, in_file, avdirs+'aver.in'
default, varfile, avdirs+'averages.dat'
default, monotone, 0
default, quiet, 0
;
;  Get necessary dimensions.
;
pc_read_dim, obj=dim, datadir=datadir, quiet=quiet
pc_set_precision, dim=dim, quiet=quiet
;
;  Read variables from *aver.in
;
spawn, "echo "+datadir+" | sed -e 's/data\/*$//g'", datatopdir
spawn, 'cat '+datatopdir+'/'+in_file, varnames

inds = where(varnames ne '')
if inds[0] eq -1 then begin
  print, 'PC_READ_XYAVER: No variables provided!'
  return
endif else $
  varnames = varnames[inds]

if (not quiet) then print, 'Preparing to read '+avdirs+'-averages ', $
    arraytostring(varnames,quote="'",/noleader)
nvar=n_elements(varnames)
;
;  Check for existence of data file.
;
filename=datadir+'/'+varfile
if (not quiet) then print, 'Reading ', filename
if (not file_test(filename)) then begin
  print, 'ERROR: cannot find file '+ filename
  stop
endif
;
;  Define arrays to put data in.
;
spawn, 'wc -l '+filename, nlines
nlines=long(nlines[0])
nlin_per_time=1L+ceil(nvar*ndir/8.)
nit=nlines/nlin_per_time
if nlines mod nlin_per_time ne 0 then $
  print, 'Warning: File "'+strtrim(filename,2)+'" corrupted!' 
;
if (not quiet) then print, 'Going to read averages at ', strtrim(nit,2), ' times'
;
;  Generate command name. Note that an empty line in the *aver.in
;  file will lead to problems. If this happened, you may want to replace
;  the empty line by a non-empty line rather than nothing, so you can
;  read the data with idl.
;
for i=0,nvar-1 do begin
  cmd=varnames[i]+'=fltarr(ndir,nit)*one'
  if (execute(cmd,0) ne 1) then message, 'Error defining data arrays'
endfor
var=fltarr(ndir*nvar)*one
times =fltarr(nit)*one
;
;  Read averages and put in arrays.
;
openr, file, filename, /get_lun
for it=0,nit-1 do begin
  ; Read time
  readf, file, t
  times[it]=t
  ; Read data
  readf, file, var
  for i=0,nvar-1 do begin
    cmd=varnames[i]+'[*,it]=var[i*ndir:(i+1)*ndir-1]'
    if (execute(cmd,0) ne 1) then message, 'Error putting data in array'
  endfor
endfor
close, file
free_lun, file
;
;  Make time monotonous and crop all variables accordingly.
;
if (monotone) then begin
  ii=monotone_array(times)
endif else begin
  ii=lindgen(n_elements(times))
endelse
;
;  Read grid.
;
pc_read_grid, obj=grid, /trim, datadir=datadir, /quiet
;
;  Put data in structure.
;
makeobject="object = create_struct(name=objectname,['t','"+dir+"'," + $
    arraytostring(varnames,quote="'",/noleader) + "]," + $
    "times[ii],grid."+dir+","+arraytostring(varnames+'[*,ii]',/noleader) + ")"
;
if (execute(makeobject) ne 1) then begin
  message, 'Error evaluating variables: ' + makeobject, /info
  undefine,object
endif
;
end
