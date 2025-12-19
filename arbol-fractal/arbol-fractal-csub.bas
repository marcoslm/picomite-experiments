' =========================================================
'  FRACTAL DEMO: THE WIND TREE
'  Recursive Calculation -> Batch Array Drawing
'  For Picomite HDMI/USB (MMBasic)
'  Requiere firmware 6.01 o superior.
'  by Marcos LM 2025
' =========================================================

OPTION EXPLICIT
OPTION DEFAULT INTEGER
CLEAR
MODE 2
MAP RESET

CONST MAX_LINES = 2071       ' 2047 lineas + 24 para stack CSUB

' Tabla de Senos Precalculada
CONST SIN_TABLE_SIZE = 360   ' Una entrada por grado
CONST FP_SHIFT = 16384       ' Escala punto fijo (2^14)
DIM INTEGER sin_table(SIN_TABLE_SIZE - 1)
DIM INTEGER map_colors(11)   ' Colores para CSUB

' Arrays Graficos
DIM INTEGER t_x1(MAX_LINES), t_y1(MAX_LINES)
DIM INTEGER t_x2(MAX_LINES), t_y2(MAX_LINES)
DIM INTEGER t_col(MAX_LINES)
DIM INTEGER t_width(MAX_LINES)  ' Grosor por linea (progresivo)

' Variables de Animacion (punto fijo para CSUB)
CONST GLOBAL_ANG_DEG = -90     ' Apuntando arriba (grados)
DIM INTEGER wind_fp            ' Viento en punto fijo
DIM INTEGER growth_fp          ' Crecimiento en punto fijo
CONST MAX_GROWTH_FP = 50 * FP_SHIFT

' Oscilacion del viento (calculado en BASIC)
CONST WIND_SLOW_SPEED = 6      ' Velocidad onda lenta (mayor = mas lento)
CONST WIND_FAST_SPEED = 4'2    ' Velocidad onda rapida (mayor = mas lento)
CONST WIND_SLOW_AMP = 10       ' Amplitud onda lenta (mayor = menos amplitud)
CONST WIND_FAST_AMP = 20       ' Amplitud onda rapida (mayor = menos amplitud)
' Efecto en ramas (pasados al CSUB)
DIM INTEGER wind_spread_base = 30'23 ' Angulo base de separacion de ramas
DIM INTEGER wind_spread_mult = 15    ' Cuanto afecta el viento al spread
DIM INTEGER wind_depth_mult = 6      ' Cuanto aumenta el efecto con la profundidad
DIM INTEGER grosor_max               ' Grosor maximo (tronco), calculado segun crecimiento
DIM INTEGER line_count

' Variables Temporales
DIM INTEGER cx = MM.HRES \ 2
DIM INTEGER cy = MM.VRES - MM.VRES \ 8

' Array de parametros para CSUB: cx, cy, growth_fp, angle_deg, wind_fp, spread_base, spread_mult, depth_mult, grosor_max
DIM INTEGER csub_params(8)

' Creamos paleta
MAP(0) = RGB(BLACK) ' Fondo seguro
' Tronco (Marron oscuro a claro)
MAP(1) = RGB(60, 40, 10)
MAP(2) = RGB(80, 50, 20)
MAP(3) = RGB(100, 70, 30)
MAP(4) = RGB(100, 110, 30)
' Hojas (Verde oscuro a brillante)
MAP(5) = RGB(0, 100, 0)
MAP(6) = RGB(0, 140, 0)
MAP(7) = RGB(20, 180, 20)
MAP(8) = RGB(40, 220, 40)
MAP(9) = RGB(60, 255, 60)
MAP(10) = RGB(80, 255, 80)
MAP(11) = RGB(100, 255, 100)
' Fondo/Cielo
MAP(12) = RGB(120,170,255)
' Suelo
MAP(13) = RGB(180,100,0)
' Texto/Blanco
MAP(15) = RGB(WHITE)
MAP SET

' Precalcular tabla de senos
DIM INTEGER i
FOR i = 0 TO SIN_TABLE_SIZE - 1
  sin_table(i) = INT(SIN(i * 2.0 * PI / SIN_TABLE_SIZE) * FP_SHIFT)
NEXT i

' Copiar colores MAP a array para CSUB
FOR i = 0 TO 11
  map_colors(i) = MAP(i)
NEXT i

' Inicializar zona de stack (2047-2070) con lineas invisibles
' para que LINE batch no dibuje basura
FOR i = 2047 TO MAX_LINES
  t_x1(i) = 0: t_y1(i) = 0
  t_x2(i) = 0: t_y2(i) = 0
  t_col(i) = MAP(12) ' Color del cielo (invisible)
NEXT i

' Creamos los framebuffers
FRAMEBUFFER CREATE
'FRAMEBUFFER LAYER ' opcional para debug
FRAMEBUFFER WRITE F

' =========================================================
'  BUCLE PRINCIPAL
' =========================================================

DO
  ' Viento: Usando tabla de senos (punto fijo)
  wind_fp = (sin_table((TIMER \ WIND_SLOW_SPEED) MOD SIN_TABLE_SIZE) \ WIND_SLOW_AMP) + (sin_table((TIMER \ WIND_FAST_SPEED) MOD SIN_TABLE_SIZE) \ WIND_FAST_AMP)
  
  ' Crecimiento: Aumenta el tamanyo hasta el limite (punto fijo)
  IF growth_fp < MAX_GROWTH_FP THEN growth_fp = growth_fp + (FP_SHIFT \ 10)
  
  ' Calcular grosor maximo segun crecimiento
  grosor_max = (growth_fp \ FP_SHIFT) \ 10 + 1
  IF grosor_max > 6 THEN grosor_max = 6
  
  ' Preparar parametros para CSUB
  csub_params(0) = cx
  csub_params(1) = cy
  csub_params(2) = growth_fp
  csub_params(3) = GLOBAL_ANG_DEG
  csub_params(4) = wind_fp
  csub_params(5) = wind_spread_base
  csub_params(6) = wind_spread_mult
  csub_params(7) = wind_depth_mult
  csub_params(8) = grosor_max
  
  ' Llenamos arrays con CSUB (9 parametros + width)
  TreeCalc csub_params(), sin_table(), map_colors(), t_x1(), t_y1(), t_x2(), t_y2(), t_col(), t_width(), line_count
  
  ' Dibujamos
  CLS MAP(12)                               ' cielo
  BOX 0, 200, 320 , 40, 1, MAP(13), MAP(13) ' suelo
  LINE t_x1(), t_y1(), t_x2(), t_y2(), t_width(), t_col()
  
  FRAMEBUFFER COPY F,N,b
 
LOOP




' =============================================================
' CSUB TreeCalc - USA ARRAYS COMO STACK
' =============================================================
CSUB TreeCalc INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER
  00000000
	464EB5F0 46DE4645 B5E04657 920EB093 46999A21 69024690 93049106 1394920D 
	DC002C00 6A86E18D 46B46B05 4EC746AA 68826C05 464D950F 6A0146B1 6B876983 
	444D6800 17C06028 981C6068 44489D1D 17D26002 980D6042 444D9A1E 17C0444A 
	602C6068 17DB6013 22006053 981F2300 444826B4 60436002 9A204653 4691434B 
	434F2200 9202139B 32014463 92089711 93100076 4CAE9B08 1E5A469C 44649B04 
	00E4469A 465344A2 9B1C6818 46989205 464344A0 9B1D6819 44A4469C 930B4663 
	9303681B 469C9B1E 466344A4 930C681F 469C9B1F 466344A4 9301681B 42B7003B 
	E0C9DA00 3BFF3B69 DAFB42B3 325A001A DB0142B2 3AFF3A69 00D29D06 9D0358AA 
	25CD436A 18121392 42AA00AD 002ADD00 42AA4D90 002ADA00 00DB9D06 9D0358EB 
	25B9436B 185B139B 00AD9300 DD0042AB 4D889500 42AB9B00 9500DA00 9D029B04 
	00ED469B 465B44AB 17C06018 9B1C6058 9B1D1958 17C96001 19596041 17D09B00 
	90096048 9B1E17D8 1959600A 9B006048 9801900A 1C43600B 930700D9 469B9B0E 
	44599B1F 6808469B 445D6849 60696028 9D029B0F 1A199801 93021C6B 9B0D4D6E 
	DD7142AB DD002804 2900E080 E082DC00 DD002906 464B2106 17C96019 9B056059 
	DC702B15 20B89B11 9B011399 9301434B 99094653 6059601A 99004643 990A6019 
	9B036059 12014358 DC0028FF 17CB2101 4650469A 34089B0B 60586019 98079B10 
	9B0118FD 9B0C4698 601D4445 605D17ED 17C54663 98046018 4684605D 466044A4 
	60029B09 981C6043 19029B00 6013980A 46526050 1903981D 9A10605A 991E6019 
	190B1ABF 601F4447 605F17FF 469C9B1F 44649B07 9B08C428 93083301 469C2308 
	4B3E9A02 429A44E1 E713D000 00179B21 23004698 E029469C DB002F00 22B4E736 
	189B0052 E731D4FB DD112900 DD002906 17C82106 6019464B 9B016058 DD8E2B09 
	2B009B05 9B05D00D E7D79308 E7ED0001 20002101 464BE7EE 21002001 60596018 
	9B21E77D 46989F02 469C17FB 9B0E981F 46404681 981E9021 46806E9C 22004660 
	17E62300 46A246BC 491846B3 9C049F1D 90009E1C 60021860 18706043 60436002 
	60021878 46406043 60021840 46486043 18404655 465D6005 48116045 42813108 
	9B21D1E8 46984667 469C9B00 46624643 605A601F BCF0B013 46B246BB 46A046A9 
	2300BDF0 469C2700 46C0E7F0 00003FF8 000007FE FFFFFE0C 0007A120 000007FF 
	000040B8 00000000 00000000 00000000 00000000 00000000 00000000 00000000 
	00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 
	00000000 00000000
END CSUB
