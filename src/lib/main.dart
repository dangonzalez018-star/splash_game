import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================
// PERSISTENCIA DE DATOS DEFENSIVA
// ==========================================
class StorageService {
  static SharedPreferences? _prefs;
  static final Map<String, String> _memStorage = {};
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint("SharedPreferences no disponible, usando memoria virtual: $e");
    }
    _initialized = true;
  }

  static Future<bool> setString(String key, String value) async {
    await init();
    if (_prefs != null) {
      try {
        return await _prefs!.setString(key, value);
      } catch (e) {
        debugPrint("Error escribiendo en SharedPreferences: $e");
      }
    }
    _memStorage[key] = value;
    return true;
  }

  static Future<String?> getString(String key) async {
    await init();
    if (_prefs != null) {
      try {
        return _prefs!.getString(key);
      } catch (e) {
        debugPrint("Error leyendo de SharedPreferences: $e");
      }
    }
    return _memStorage[key];
  }

  static Future<bool> remove(String key) async {
    await init();
    if (_prefs != null) {
      try {
        return await _prefs!.remove(key);
      } catch (e) {
        debugPrint("Error eliminando de SharedPreferences: $e");
      }
    }
    _memStorage.remove(key);
    return true;
  }

  static Future<bool> clear() async {
    await init();
    if (_prefs != null) {
      try {
        return await _prefs!.clear();
      } catch (e) {
        debugPrint("Error limpiando SharedPreferences: $e");
      }
    }
    _memStorage.clear();
    return true;
  }
}

// ==========================================
// JUEGO BASE: RETOS POR DEFECTO
// ==========================================
const String kPuebloEventCard = "¡RONDA DE CHUPITOS DEL PUEBLO! Todos los jugadores se toman un chupito obligatorio. ¡El pueblo se ha vengado de vuestros pecados!";

const List<String> kDefaultChallenges = [
  "Durante las próximas 3 rondas, tienes que hablar imitando el acento de otra región/país. Si te ríes o te equivocas, chupito.",
  "Tienes que enviar un mensaje de audio a quien quieras (o a la última persona con la que ligaste) diciendo solo: 'Sé lo que hiciste'. Sin dar explicaciones.",
  "El grupo elige a una persona. Tienes que dejar que esa persona te dibuje lo que quiera (NO VALE PITOS) con un boli/rotulador. Te lo dejas hasta que acabe el juego.",
  "Llama a un familiar y dile que te vas a casar la semana que viene en el viaje. Tienes que aguantar la mentira 1 minuto.",
  "Llama a un familiar y dile que vas a ser padre o el abuelo/abuela. Tienes que aguantar la mentira 1 minuto.",
  "Deja que el jugador de tu derecha te mire los mensajes directos de Instagram durante 30 segundos.",
  "Hazle un masaje de pies de 1 minuto al jugador que tengas a tu izquierda.",
  "Ponte toda la ropa que puedas del revés (camiseta, pantalones, calcetines) en menos de 1 minuto.",
  "Tienes que confesar cuál es el secreto más sucio que sabes de alguien de esta mesa (sin decir el nombre si no quieres morir).",
  "Tienes que recrear una escena romántica de película con una de las personas randoms que veas o que tengas enfrente ahora mismo.",
  "Reto a muerte: Reta a quien quieras a un pulso. El que pierda, se toma el chupito de este reto y además se le suma un +1 a su contador.",
  "Tienes que convencer a alguien para que te dé un abrazo voluntario (O un beso si estás soltero) en los próximos 2 minutos. No puedes decir que es un reto.",
  "Elige a un jugador. A partir de ahora, cada vez que él beba (por reto o por su cuenta), tú tienes que beber con él las próximas 2 rondas o 30min.",
  "Di tres cosas que te molestan de la persona que tienes a tu derecha. Sé jodidamente honesto.",
  "Cámbiele una prenda de ropa a la persona que tienes enfrente. Os la tenéis que quedar puesta hasta que termine el juego.",
  "Mantén una mirada fija con el jugador de tu izquierda durante 1 minuto sin pestañear ni reírte. El primero que falle, bebe.",
  "Nombra a los 3 jugadores que crees que peor vestirían si no les ayudaran. Si el pueblo está de acuerdo beben los 3 jugadores, si no pierdes y bebes chupito.",
  "Deja que el grupo te vende los ojos. Tienes que adivinar quién es quién tocándoles solo las manos. Tienes 3 intentos.",
  "Elige a tu 'esclavo'. Durante los próximos 15 minutos, tiene que traerte la bebida o lo que pidas (NO TE PASES, EL PUEBLO SUPERVISA). Si se niega, se toma 3 chupitos. (SI TE PASAS TE LOS BEBES TÚ).",
  "Cuenta la historia de cómo perdiste la virginidad con todo lujo de detalles. Si te niegas, te sumas +2 chupitos directamente.",
  "¿Quién de esta mesa crees que ganaría más dinero en OnlyFans? Que vote el pueblo. El elegido escoge quién bebe.",
  "Di el nombre de la persona del grupo que crees que tardará más en ser papá. El elegido escoge quién bebe.",
  "Responde con la verdad: ¿Has mentido en este viaje a alguno de los que está sentado aquí? Si es sí, cuenta qué fue.",
  "Deja el móvil desbloqueado en el centro de la mesa. El próximo mensaje que te llegue, lo lee el grupo en voz alta.",
  "Di en voz alta la mayor inseguridad que tienes sobre tu físico o tu personalidad.",
  "¡Ronda Relámpago! El jugador que ha salido tiene que decir marcas de coches VS EL HÉROE DEL PUEBLO. El primero que tarde más de 5 segundos o repita una, bebe.",
  "¡El suelo es lava! En cuanto termine este pop-up, el último en subirse a una silla o despegar los pies del suelo se toma un chupito.",
  "¡Cascada masiva! Todos empiezan a beber a la vez. No puedes parar de beber hasta que el jugador de tu derecha pare. Empieza el jugador seleccionado.",
  "¡Voto secreto! A la de tres, todos señalan a la persona que creen que va a acabar peor esta noche. El que tenga más dedos apuntándole, bebe.",
  "¡Simetría! Durante las próximas 2 rondas, todo lo que haga el jugador de tu derecha (beber, rascarse, hablar), tú tienes que imitarlo.",
  "¡El Prohibido! El grupo elige una palabra común (ej: 'sí', 'no', 'chupito'). Cualquiera que la diga durante los próximos 10 minutos, bebe.",
  "¡Pregunta caliente! El jugador seleccionado le hace una pregunta anónima (escribiéndola en el móvil) a otra persona del grupo. Si no la responde, bebe esa persona; si la responde, bebe el que preguntó.",
  "¡El mudo! No puedes hablar hasta que vuelva a ser tu turno o el temporizador gris se ponga amarillo. Si hablas, +1 chupito.",
  "¡Tira de la cuerda! Eliges a un jugador. Os jugáis un 'Piedra, papel o tijera'. El que pierda se toma los chupitos acumulados del otro.",
  "¡Castigo del Pueblo! Si el contador del 'Pueblo' está a la mitad o más de los jugadores, todos los que tengan 0 chupitos en su contador personal se toman uno ahora mismo por cobardes.",
  "Intercambia el móvil con el jugador de tu izquierda. Durante los próximos 10 minutos, si le llega una notificación, la tiene que leer él en voz alta.",
  "Tienes que estar las próximas 2 rondas con un calcetín puesto en la mano como si fuera una marioneta. Cada vez que hables, la marioneta tiene que hablar por ti.",
  "Intenta hacer el pino contra la pared o tocarte las puntas de los pies sin doblar las rodillas durante 10 segundos. Si no tienes flexibilidad, ¡chupito!",
  "Intenta hacer el pino contra la pared o tocarte las puntas de los pies sin doblar las rodillas durante 20 segundos. Si no tienes flexibilidad, ¡chupito!",
  "Tienes que hacer 10 flexiones ahora mismo en medio de la sala mientras el grupo te cuenta los números en voz alta.",
  "Ponte los zapatos en los pies cambiados (el izquierdo en el derecho y viceversa) y camina así durante 2 minutos.",
  "Conviértete en estatua. No puedes moverte ni un milímetro hasta que otra persona de la mesa beba (por el motivo que sea) o convenzan a alguien para que te dé un beso. Si parpadeas muy obvio o te mueves, pierdes.",
  "¿Cuál es el lugar más extraño en el que has tenido una aventura o un lío amoroso?",
  "Si te dieran 10.000€ por besar a uno de tus amigos de esta mesa ahora mismo en los labios durante 5 segundos, ¿a quién elegirías?",
  "El Guardaespaldas: Elige a un jugador. Durante los próximos 15 minutos, cada vez que alguien le haga una pregunta, tienes que responder tú por él. Si él habla, bebe él; si tú fallas, bebes tú.",
  "El Francotirador: El grupo te da una palabra secreta en el móvil. Tienes que conseguir que alguien de la mesa la diga de forma natural en los próximos 10 minutos. Si lo logras, esa persona bebe. Si nadie la dice, te sumas +1 chupito.",
  "Sin Pulgares: Te vendan los pulgares de ambas manos con celo/cinta. Tienes que intentar beber o usar el móvil sin usar los pulgares durante las próximas 3 rondas.",
  "El Eco: Cada vez que el jugador de tu izquierda diga una frase, tú tienes que repetir las últimas dos palabras en voz baja inmediatamente después. Si te olvidas, chupito.",
  "¡El Juicio Final! Todos cierran los ojos. A la de tres, todos señalan al que creen que es el 'cerebro' que peor idea ha tenido en este viaje. Al abrir los ojos, el más señalado se lleva +1 chupito.",
  "¡La Ruleta Rusa! Se llenan 3 vasos tapados (dos con agua, uno con la bebida fuerte del viaje). El jugador seleccionado elige uno a ciegas y se lo toma. ¡Suerte!",
  "Intercambio de identidades: Elige a un amigo de la mesa. Durante los próximos 10 minutos, cada vez que te toque hablar, tienes que imitar sus gestos, sus expresiones y su forma de hablar. Si rompes el personaje, chupito.",
  "El negociador: Tienes que acercarte a una mesa de desconocidos y convencerles de que os regalen una patata frita, un hielo, un trozo de comida, un sorbo de su bebida o su instagram...",
  "La foto oficial: Acércate a alguien que no conozcas y pídele una foto, pero con una condición: tienes que posar con esa persona como si fuera tu mejor amigo de la infancia de toda la vida.",
  "El consultor de moda: Ve hacia un desconocido que veas que va bien vestido y dile, con total seriedad: 'Perdona, mi amigo de allí dice que ese outfit te queda fatal, pero yo creo que estás increíble. ¿Me dices dónde lo has comprado?'.",
  "El brindis infiltrado: Ve a otra mesa o barra, intégrate en una conversación de desconocidos durante al menos 30 segundos y consigue hacer un brindis con ellos antes de volver con tu grupo.",
  "El ligón despistado: Acércate a alguien que te llame la atención fuera del grupo y pídele el número de teléfono... pero usando la frase de ligar más rancia, mala o cliché que se te ocurra (ej: '¿Te ha dolido caer del cielo?').",
  "El cumpleañero falso: Convence a los camareros del local (o a una mesa de al lado) de que hoy es tu cumpleaños para que te canten el 'Cumpleaños Feliz'. El grupo tiene que grabarlo en vídeo.",
  "El club de fans: Acércate a un desconocido, quédate mirándole con cara de asombro y dile: '¡No me lo puedo creer! ¿Eres tú de verdad? ¿Me puedes hacer un autógrafo/foto?' como si fuera un famoso. Tienes que mantener la mentira hasta el final.",
  "La encuesta absurda: Ve a hablar con alguien fuera del grupo y hazle una pregunta totalmente absurda con cara de máxima seriedad, como por ejemplo: 'Disculpa, estamos debatiendo allí: ¿tú eres más de tortilla con cebolla, sin cebolla, o crees que la pizza con piña es un crimen de guerra?'.",
  "El lector de mentes: Acércate a alguien y dile: 'Hola, estoy practicando lectura de mente. Sé exactamente en qué estás pensando ahora mismo'. Tienes que intentar adivinar basándose en 2 cosas su ropa o actitud; tienes que hacerla reír.",
  "El baile improvisado: Sal a la pista de baile (o en medio de la calle/terraza) y saca a bailar a un desconocido durante al menos 15 segundos. Tienes que darlo todo, con vueltas incluidas.",
  "El camarero por un minuto: Ve a la barra y pídele al camarero que te deje pasar al otro lado para servir una copa, o ayúdale a recoger tres vasos vacíos de una mesa vecina de desconocidos.",
  "El piropo elegante: Elige a un desconocido (da igual chico o chica) y ve exclusivamente a decirle un cumplido sincero y educado sobre sus ojos, su sonrisa o su pelo, dale las gracias y date la vuelta sin pedir nada a cambio.",
  "El gurú espiritual: Acércate a un desconocido que esté serio, ponle una mano en el hombro de forma mística y dile: 'El universo me ha dicho que hoy va a ser el mejor día de tu vida. Créetelo'. Date la vuelta dramáticamente y vuelve con tus amigos.",
  "El catador infiltrado: Acércate a alguien que esté tomando un cóctel o una copa que tenga buena pinta y pregúntale: 'Perdona, es que te veo beber eso con tanta clase que necesito saber qué es para pedirme uno igual'.",
  "Intercambio de chupitos: Convence a un desconocido en la barra para que se tome un chupito contigo, pero tú pagas el suyo y él tiene que pagar el tuyo (o convencer al camarero de que os invite a ambos).",
  "El DJ por un momento: Ve a hablar con el camarero o el DJ del local y consigue que ponga una canción específica que tu grupo elija. Si suena en los próximos 10 minutos, reto superado.",
  "El taburete prestado: Ve a una mesa de desconocidos donde haya una silla o taburete vacío. Tienes que convencerles de que te dejen sentarte con ellos exactamente 1 minuto porque 'tus amigos te están haciendo el vacío'.",
  "El juego de las adivinanzas: Ve a una mesa de desconocidos y diles: 'Nos estamos jugando una apuesta allí. ¿A que adivino de qué ciudad/país sois solo con miraros?'. Tienes 3 intentos.",
  "El brindis de película: Levántate en medio del bar, alza tu copa y grita un brindis motivacional (ej: '¡Por las vacaciones y porque mañana seremos ricos!'). Consigue que al menos otra mesa de desconocidos brinde, aplauda, grite o celebre contigo.",
  "El protector de copas: Acércate a alguien fuera del grupo con cara de preocupación y dile: 'Oye, vigila tu copa, que he visto a un grupo de guapos mirándola con envidia (señalando a tus amigos)'.",
  "El favor absurdo: Consigue que un desconocido te guarde un objeto totalmente sin valor (un posavasos, un mechero sin gas) durante 5 minutos prometiéndole que 'luego vuelves a por ello porque es una reliquia'.",
  "El guardaespaldas falso: Elige a uno del grupo y vais a la barra por detrás de él con los brazos cruzados y cara de pocos amigos, haciendo de su guardaespaldas durante 30 segundos.",
  "El aplauso masivo: Consigue que un grupo de desconocidos le dé un aplauso cerrado a uno de tus amigos de la mesa cuando este se levante a ir al baño.",
  "La confesión dramática: Acércate a un desconocido, mírale fijamente y dile con tono dramático: 'Sé que no me conoces, pero el destino me ha dicho que hoy tenía que darte esto'. Dale un azucarillo, un ticket o un posavasos firmado y vete corriendo.",
  "El poeta callejero: Acércate a alguien y recítale las dos primeras líneas de una canción famosa (tipo reggaetón antiguo o clásico) como si fuera un poema profundo y serio.",
  "El duelo de chistes: Ve a una mesa vecina y pídeles hacer un duelo: tú cuentas un chiste y ellos otro. El que haga reír al otro grupo primero gana. Si pierdes, te toca beber.",
  "La conexión astrológica: Pregúntale el signo del zodiaco a un desconocido. Sea cual sea el que te diga, responde: 'Madre mía, sabía que eras [Signo], se nota tu energía a un kilómetro', y dale una explicación inventada.",
  "El consejo de sabios: Ve a una mesa de gente que sea visiblemente mayor o más joven que vosotros y pídeles un consejo rápido sobre 'cómo sobrevivir a un viaje con estos salvajes (señalando a tu mesa)'.",
  "El camarero infiltrado II: Ve a una mesa de desconocidos y, con toda la cara del mundo, pregúntales: '¿Todo bien por aquí? ¿Os falta algo?' como si fueras el encargado del local.",
  "El abrazo de oso: Consigue que un desconocido te dé un abrazo de más de 3 segundos porque 'lo necesitas para empezar bien las vacaciones'.",
  "El adivino de nombres: Ve hacia alguien y dile: 'Tengo un sexto sentido. Sé que te llamas... [di un nombre al azar]'. Si aciertas (milagro), te salvas, sino chupito.",
  "El seguidor secreto: Pídele el Instagram a un desconocido de una forma original: 'Oye, mi algoritmo está aburrido, ¿me dejas seguirte para ver si tu vida es más interesante que la mía?'.",
  "La huella digital: Consigue que un desconocido te dé una tontería/objeto o dibuje algo con boli en una servilleta (como un autógrafo o un amuleto de la suerte para el viaje).",
  "El náufrago del viaje: Ve a otra mesa y diles: 'Mis amigos me han castigado sin hablar en nuestra mesa. ¿Me adoptáis aquí 2 minutos?'.",
  "La llamada del millón: Camina entre las mesas de desconocidos fingiendo una llamada de teléfono muy importante y di en voz alta: '¡Que no, que te digo que el cargamento de unicornios llega mañana a Salou!' con total seriedad.",
  "El deportista desubicado: Levántate de la mesa, ve a una zona despejada del local o la calle y ponte a hacer estiramientos de atleta profesional (como si fueras a correr los 100 metros lisos) durante 30 segundos. Luego vuelve y siéntate normal.",
  "La pasarela de moda: Ve al baño del local (o da una vuelta por el bar) caminando como si fuera un modelo de alta costura en una pasarela de París: mirada fija, pasos exagerados y pose dramática al girar.",
  "El susurro místico: Pasa cerca de una mesa de desconocidos y, sin pararte ni mirar a nadie, di en voz baja pero audible: 'El código ha sido activado'. Sigue caminando como si nada.",
  "El detractor: Durante los próximos 10 minutos, tienes que llevarle la contraria absolutamente en todo lo que diga la persona que tú apuntes en el móvil. Si te pillan, bebes.",
  "El impostor del grupo: El grupo elige una palabra secreta. Tienes que conseguir meterla en tus frases de forma natural en los próximos 3 turnos. Si alguien te pilla y grita '¡SPLASH!', te sumas +1 chupito.",
  "El juego del silencio: No puedes volver a usar las palabras 'Sí', 'No', 'Yo' o 'Tú' hasta que el temporizador gris se vuelva amarillo. Si te cazan usándolas, chupito.",
  "El cambio de sitio dramático: En cuanto acabe este pop-up, tienes que cambiarte de sitio con el jugador que tenga más chupitos acumulados y heredar su 'energía'.",
  "El Rey del Silencio: A partir de ahora, tienes prohibido hablar. Solo puedes comunicarte con el grupo haciendo mímica y gestos absurdos hasta que el botón ¿SPLASH? vuelva a estar activo en la app.",
  "SANGILARI: Si tú no tienes bebida, te libras, enhorabuena. Lo siento para quien tenga más bebida: le pasas la patata caliente... En caso de que dos o más jugadores tengan igualdad, piedra, papel o tijeras decidirá."
];

// ==========================================
// PUNTO DE ENTRADA PRINCIPAL
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const SplashApp());
}

class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '¡SPLASH!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFD32F2F), // Crimson Red
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD32F2F),
          secondary: Color(0xFFFFC107), // Amber / Splash Yellow
          surface: Color(0xFF1E1E1E),
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(),
    );
  }
}

// ==========================================
// PANTALLA PRINCIPAL
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  bool _hasSavedGame = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedGame() async {
    final active = await StorageService.getString('isGameActive');
    setState(() {
      _hasSavedGame = (active == 'true');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB71C1C), // Deep Red
              Color(0xFF5F0909), // Crimson Dark
              Color(0xFF1A0202), // Dark Brown/Red
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Elementos visuales decorativos flotantes de fondo
              Positioned(
                top: 40,
                left: -20,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(Icons.wine_bar, size: 200, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: -30,
                right: -40,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(Icons.flash_on, size: 280, color: Colors.white),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),
                    
                    // LOGO ANIMADO SPLASH
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.06),
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFFFC107).withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFC107).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Text(
                          '¡SPLASH!',
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFC107),
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: const Offset(3, 3),
                                blurRadius: 6,
                              ),
                              Shadow(
                                color: const Color(0xFFD32F2F),
                                offset: const Offset(-2, -2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'El juego definitivo de tus vacaciones',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1.2,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    
                    const Spacer(flex: 3),
                    
                    // BOTÓN: REANUDAR PARTIDA (Si existe)
                    if (_hasSavedGame) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const GameScreen()),
                            ).then((_) => _checkSavedGame());
                          },
                          icon: const Icon(Icons.play_arrow, size: 28, color: Colors.black),
                          label: const Text(
                            'REANUDAR PARTIDA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107), // Yellow Splash
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 8,
                            shadowColor: const Color(0xFFFFC107).withOpacity(0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // BOTÓN: NUEVA PARTIDA
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (_hasSavedGame) {
                            _showConfirmNewGameDialog();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SetupScreen()),
                            ).then((_) => _checkSavedGame());
                          }
                        },
                        icon: const Icon(Icons.add, size: 24, color: Colors.white),
                        label: Text(
                          _hasSavedGame ? 'INICIAR OTRA PARTIDA' : 'NUEVA PARTIDA',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                          backgroundColor: Colors.black.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    
                    const Spacer(flex: 2),
                    
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'v1.0.0 • 100% Local • ¡Salud! 🍻',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmNewGameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('¿Empezar de cero?'),
        content: const Text(
          'Tienes una partida guardada activa. Si empiezas una nueva partida, perderás todos los contadores de chupitos y el estado actual.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar popup
              StorageService.clear(); // Limpiar partida guardada
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SetupScreen()),
              ).then((_) => _checkSavedGame());
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            child: const Text('NUEVA PARTIDA', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PANTALLA DE CONFIGURACIÓN
// ==========================================
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final List<String> _playerNames = [];
  final TextEditingController _nameController = TextEditingController();
  double _countdownMinutes = 15;
  bool _testMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_playerNames.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese nombre ya está en la partida.')),
      );
      return;
    }
    if (_playerNames.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El límite máximo es de 20 jugadores.')),
      );
      return;
    }
    setState(() {
      _playerNames.add(name);
      _nameController.clear();
    });
  }

  void _removePlayer(int index) {
    setState(() {
      _playerNames.removeAt(index);
    });
  }

  void _startGame() {
    if (_playerNames.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas al menos 2 jugadores para empezar.')),
      );
      return;
    }

    // Popup de confirmación
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Confirmar Partida'),
        content: Text(
          '¿Estás seguro de iniciar la partida con ${_playerNames.length} jugadores?\n\n'
          'Jugadores: ${_playerNames.join(", ")}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('EDITAR JUGADORES', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Cierra popup
              await _saveInitialGameState();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const GameScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
            child: const Text('¡A JUGAR!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveInitialGameState() async {
    // Inicializar contadores de jugadores
    final Map<String, int> initialShots = {for (var name in _playerNames) name: 0};
    
    // Configurar pools
    final List<int> challengeIndices = List.generate(kDefaultChallenges.length, (index) => index);
    challengeIndices.shuffle();

    await StorageService.setString('isGameActive', 'true');
    await StorageService.setString('players', jsonEncode(_playerNames));
    await StorageService.setString('playerShots', jsonEncode(initialShots));
    await StorageService.setString('puebloScore', '0');
    await StorageService.setString('remainingDareIndices', jsonEncode(challengeIndices));
    
    // Segundos del temporizador
    int seconds = _testMode ? _countdownMinutes.round() : (_countdownMinutes.round() * 60);
    await StorageService.setString('countdownSeconds', seconds.toString());
    await StorageService.setString('testMode', _testMode.toString());
    await StorageService.setString('isCountdownActive', 'false');
    await StorageService.remove('countdownEndTime');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Partida'),
        backgroundColor: const Color(0xFFB71C1C),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5F0909), Color(0xFF1A0202)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // AGREGAR JUGADORES
                Card(
                  color: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AÑADIR JUGADORES (2 - 20)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFC107),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  hintText: 'Nombre del amigo...',
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.3),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                textCapitalization: TextCapitalization.words,
                                onSubmitted: (_) => _addPlayer(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addPlayer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD32F2F),
                                padding: const EdgeInsets.all(14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),

                // LISTA DE JUGADORES AÑADIDOS
                Expanded(
                  child: Card(
                    color: Colors.black.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: _playerNames.isEmpty
                        ? Center(
                            child: Text(
                              'Añade a tus amigos para empezar el viaje.',
                              style: TextStyle(color: Colors.white.withOpacity(0.5)),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3.5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _playerNames.length,
                            itemBuilder: (context, index) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _playerNames[index],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                                        onPressed: () => _removePlayer(index),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                
                const SizedBox(height: 12),

                // TEMPORIZADOR DE ESPERA ENTRE RONDAS
                Card(
                  color: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TIEMPO DE ESPERA ENTRE RONDAS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFC107),
                              ),
                            ),
                            // Botón de modo prueba
                            Row(
                              children: [
                                const Text('Prueba (Seg)', style: TextStyle(fontSize: 11, color: Colors.white60)),
                                Switch(
                                  value: _testMode,
                                  activeColor: const Color(0xFFFFC107),
                                  onChanged: (val) {
                                    setState(() {
                                      _testMode = val;
                                      if (_testMode) {
                                        _countdownMinutes = 15; // Segundos por defecto
                                      } else {
                                        _countdownMinutes = 15; // Minutos por defecto
                                      }
                                    });
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                        Slider(
                          value: _countdownMinutes,
                          min: 15,
                          max: 30,
                          divisions: 15,
                          activeColor: const Color(0xFFFFC107),
                          inactiveColor: Colors.white12,
                          label: _testMode 
                              ? '${_countdownMinutes.round()} segundos'
                              : '${_countdownMinutes.round()} minutos',
                          onChanged: (val) {
                            setState(() {
                              _countdownMinutes = val;
                            });
                          },
                        ),
                        Center(
                          child: Text(
                            _testMode 
                                ? 'Tiempo de espera: ${_countdownMinutes.round()} segundos'
                                : 'Tiempo de espera: ${_countdownMinutes.round()} minutos',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),

                // BOTÓN EMPEZAR
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'CREAR PARTIDA (${_playerNames.length} JUGADORES)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA PRINCIPAL DEL JUEGO
// ==========================================
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  // Estado del juego
  List<String> _players = [];
  Map<String, int> _playerShots = {};
  int _puebloScore = 0;
  List<int> _remainingDareIndices = [];
  int _countdownDuration = 900; // segundos
  bool _testMode = false;

  // Temporizador
  bool _isCountdownActive = false;
  int _countdownEndTime = 0;
  int _secondsLeft = 0;
  Timer? _timer;

  // Estado del giro
  bool _isSpinning = false;
  late ScrollController _challengeScrollController;
  late ScrollController _playerScrollController;

  // Ganadores seleccionados tras el giro
  String _selectedPlayer = "";
  String _selectedChallenge = "";
  bool _isPuebloCardActive = false;

  // Para el efecto visual del spinner
  List<String> _challengeSpinnerItems = [];
  List<String> _playerSpinnerItems = [];

  final double _challengeItemWidth = 220.0;
  final double _playerItemWidth = 140.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _challengeScrollController = ScrollController();
    _playerScrollController = ScrollController();
    _loadGameState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _challengeScrollController.dispose();
    _playerScrollController.dispose();
    super.dispose();
  }

  // Guardar partida si el usuario sale de la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveGameState();
    }
  }

  // ==========================================
  // CARGA Y GUARDADO DE ESTADO
  // ==========================================
  Future<void> _loadGameState() async {
    final active = await StorageService.getString('isGameActive');
    if (active != 'true') return;

    final playersStr = await StorageService.getString('players') ?? '[]';
    final shotsStr = await StorageService.getString('playerShots') ?? '{}';
    final puebloStr = await StorageService.getString('puebloScore') ?? '0';
    final remainingStr = await StorageService.getString('remainingDareIndices') ?? '[]';
    final durationStr = await StorageService.getString('countdownSeconds') ?? '900';
    final testModeStr = await StorageService.getString('testMode') ?? 'false';
    final isCountdownActiveStr = await StorageService.getString('isCountdownActive') ?? 'false';
    final endTimeStr = await StorageService.getString('countdownEndTime');

    setState(() {
      _players = List<String>.from(jsonDecode(playersStr));
      _playerShots = Map<String, int>.from(jsonDecode(shotsStr));
      _puebloScore = int.parse(puebloStr);
      _remainingDareIndices = List<int>.from(jsonDecode(remainingStr));
      _countdownDuration = int.parse(durationStr);
      _testMode = (testModeStr == 'true');
      _isCountdownActive = (isCountdownActiveStr == 'true');
      
      if (_isCountdownActive && endTimeStr != null) {
        _countdownEndTime = int.parse(endTimeStr);
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now >= _countdownEndTime) {
          _isCountdownActive = false;
          _secondsLeft = 0;
          StorageService.setString('isCountdownActive', 'false');
        } else {
          _secondsLeft = ((_countdownEndTime - now) / 1000).ceil();
          _startTimer();
        }
      }
    });

    _initializeSpinnerPlaceholders();
  }

  Future<void> _saveGameState() async {
    await StorageService.setString('players', jsonEncode(_players));
    await StorageService.setString('playerShots', jsonEncode(_playerShots));
    await StorageService.setString('puebloScore', _puebloScore.toString());
    await StorageService.setString('remainingDareIndices', jsonEncode(_remainingDareIndices));
    await StorageService.setString('isCountdownActive', _isCountdownActive.toString());
    if (_isCountdownActive) {
      await StorageService.setString('countdownEndTime', _countdownEndTime.toString());
    } else {
      await StorageService.remove('countdownEndTime');
    }
  }

  void _initializeSpinnerPlaceholders() {
    // Generar datos aleatorios visuales iniciales en el spinner
    final r = math.Random();
    _challengeSpinnerItems = List.generate(15, (_) => kDefaultChallenges[r.nextInt(kDefaultChallenges.length)]);
    _playerSpinnerItems = List.generate(15, (_) => _players.isNotEmpty ? _players[r.nextInt(_players.length)] : "Jugador");
  }

  // ==========================================
  // LOGICA DEL JUEGO
  // ==========================================
  void _triggerSplash() {
    if (_isSpinning || _isCountdownActive) return;

    setState(() {
      _isSpinning = true;
    });

    final random = math.Random();

    // 1. Determinar si se inyecta la carta del Pueblo
    bool mustTriggerPuebloCard = (_puebloScore >= _players.length);

    // 2. Elegir reto
    int chosenDareIndex = 0;
    if (mustTriggerPuebloCard) {
      _selectedChallenge = kPuebloEventCard;
      _isPuebloCardActive = true;
    } else {
      _isPuebloCardActive = false;
      // Comprobar si el pool de retos está vacío, si es así reiniciamos
      if (_remainingDareIndices.isEmpty) {
        _remainingDareIndices = List.generate(kDefaultChallenges.length, (index) => index);
        _remainingDareIndices.shuffle();
      }
      
      // Tomar el primer índice disponible y sacarlo del pool
      chosenDareIndex = _remainingDareIndices.removeAt(0);
      _selectedChallenge = kDefaultChallenges[chosenDareIndex];
    }

    // 3. Elegir jugador (el pueblo no entra aquí)
    _selectedPlayer = _players[random.nextInt(_players.length)];

    // 4. Preparar listas de animación para el spinner (Casino style)
    // Crearemos una lista larga donde el elemento en el índice 20 es el ganador
    const int targetIndex = 20;

    List<String> tempChallenges = [];
    for (int i = 0; i < targetIndex; i++) {
      tempChallenges.add(kDefaultChallenges[random.nextInt(kDefaultChallenges.length)]);
    }
    tempChallenges.add(_selectedChallenge); // Ganador en el índice targetIndex
    for (int i = 0; i < 5; i++) {
      tempChallenges.add(kDefaultChallenges[random.nextInt(kDefaultChallenges.length)]);
    }

    List<String> tempPlayers = [];
    for (int i = 0; i < targetIndex; i++) {
      tempPlayers.add(_players[random.nextInt(_players.length)]);
    }
    tempPlayers.add(_selectedPlayer); // Ganador
    for (int i = 0; i < 5; i++) {
      tempPlayers.add(_players[random.nextInt(_players.length)]);
    }

    setState(() {
      _challengeSpinnerItems = tempChallenges;
      _playerSpinnerItems = tempPlayers;
    });

    // Resetear scroll controllers al principio sin animación
    _challengeScrollController.jumpTo(0);
    _playerScrollController.jumpTo(0);

    // Animamos hacia el objetivo centrado exacto considerando el ancho fijo de 320px
    // y los márgenes de 4px horizontales de cada item. El centro de la pantalla está en 160px.
    final double challengeTargetOffset = (targetIndex * (_challengeItemWidth + 8)) + 4 + (_challengeItemWidth / 2) - 160;
    final double playerTargetOffset = (targetIndex * (_playerItemWidth + 8)) + 4 + (_playerItemWidth / 2) - 160;

    _challengeScrollController.animateTo(
      challengeTargetOffset,
      duration: const Duration(milliseconds: 2500),
      curve: Curves.easeOutCubic,
    );

    _playerScrollController.animateTo(
      playerTargetOffset,
      duration: const Duration(milliseconds: 2500),
      curve: Curves.easeOutCubic,
    );

    // Finalizar animación
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() {
        _isSpinning = false;
      });
      _showResultDialog();
    });
  }

  // ==========================================
  // CONTADOR DE ESPERA
  // ==========================================
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _isCountdownActive = false;
          _timer?.cancel();
          StorageService.setString('isCountdownActive', 'false');
        }
      });
    });
  }

  void _activateCountdown() {
    setState(() {
      _isCountdownActive = true;
      _secondsLeft = _countdownDuration;
      _countdownEndTime = DateTime.now().millisecondsSinceEpoch + (_countdownDuration * 1000);
    });
    _saveGameState();
    _startTimer();
  }

  // ==========================================
  // DIÁLOGOS Y POPUPS
  // ==========================================
  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: _isPuebloCardActive ? const Color(0xFFD32F2F) : const Color(0xFFFFC107).withOpacity(0.5),
            width: 2,
          ),
        ),
        title: Center(
          child: Text(
            _isPuebloCardActive ? '💥 ¡EVENTO GRUPAL! 💥' : '🔥 RETO ASIGNADO 🔥',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _isPuebloCardActive ? Colors.redAccent : const Color(0xFFFFC107),
              fontSize: 20,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isPuebloCardActive) ...[
              const Text('LE TOCA A:', style: TextStyle(fontSize: 12, color: Colors.white54)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _selectedPlayer.toUpperCase(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text('EL RETO:', style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 8),
            Text(
              _selectedChallenge,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: _isPuebloCardActive
            ? [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _puebloScore = 0; // Reset pueblo
                    });
                    _activateCountdown();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('¡SALUD Y A CELEBRAR!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ]
            : [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // BOTON: RETO SUPERADO
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _activateCountdown();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('SUPERADO', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        // BOTON: CHUPITO
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _playerShots[_selectedPlayer] = (_playerShots[_selectedPlayer] ?? 0) + 1;
                            });
                            _activateCountdown();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('CHUPITO (+1)', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // BOTON: COIN FLIP
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Cierra popup de resultado
                            _showCoinFlipDialog();
                          },
                          icon: const Icon(Icons.monetization_on, color: Colors.black),
                          label: const Text('COIN FLIP (50% SALVADO / X2)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
      ),
    );
  }

  void _showCoinFlipDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CoinFlipDialog(
        playerName: _selectedPlayer,
        onFlipFinished: (isSaved) {
          setState(() {
            if (isSaved) {
              _puebloScore += 1;
            } else {
              _playerShots[_selectedPlayer] = (_playerShots[_selectedPlayer] ?? 0) + 2;
            }
          });
          _activateCountdown();
        },
      ),
    );
  }

  void _showVerJugadoresDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Jugadores Activos'),
            Icon(Icons.wine_bar, color: Colors.red.shade700),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _players.length,
            itemBuilder: (context, index) {
              final player = _players[index];
              final score = _playerShots[player] ?? 0;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      player,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w900,
                            color: score > 0 ? Colors.redAccent.shade400 : Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.wine_bar, 
                          size: 16, 
                          color: score > 0 ? Colors.redAccent.shade400 : Colors.grey,
                        )
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
            child: const Text('ENTENDIDO', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _exitGame(bool shouldSave) async {
    if (shouldSave) {
      await _saveGameState();
    } else {
      await StorageService.clear();
    }
    if (mounted) {
      Navigator.pop(context); // Volver a main screen
    }
  }

  // ==========================================
  // FORMATO DE TIEMPO
  // ==========================================
  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int secs = seconds % 60;
    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secsStr = secs.toString().padLeft(2, '0');
    return '$minutesStr:$secsStr';
  }

  // ==========================================
  // CONSTRUCCIÓN DE INTERFAZ
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5F0909), Color(0xFF1A0202)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CABECERA (Pueblo y Menu)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Pueblo HUD (Fantasma de Pueblo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _puebloScore >= _players.length 
                              ? Colors.redAccent 
                              : Colors.white24,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.group, 
                            size: 18, 
                            color: _puebloScore >= _players.length 
                                ? Colors.redAccent 
                                : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PUEBLO', style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
                              Text(
                                '$_puebloScore / ${_players.length}',
                                style: TextStyle(
                                  fontSize: 14, 
                                  fontWeight: FontWeight.bold,
                                  color: _puebloScore >= _players.length 
                                      ? Colors.redAccent 
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Logo central chiquito
                    const Text(
                      '¡SPLASH!',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFC107),
                        letterSpacing: 2,
                        fontSize: 20,
                      ),
                    ),

                    // Botón de opciones
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'ver') {
                          _showVerJugadoresDialog();
                        } else if (val == 'pausa') {
                          _exitGame(true);
                        } else if (val == 'terminar') {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1E1E),
                              title: const Text('¿Eliminar partida?'),
                              content: const Text('Si terminas la partida se borrarán permanentemente todos los contadores de chupitos actuales.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _exitGame(false);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                                  child: const Text('BORRAR', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'ver', child: Text('👤 Ver Jugadores')),
                        const PopupMenuItem(value: 'pausa', child: Text('⏸️ Pausar Juego')),
                        const PopupMenuItem(value: 'terminar', child: Text('🛑 Terminar Partida')),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white12, height: 1),
              
              // PANEL DE RUEDAS / CINTAS O TEMPORIZADOR
              Expanded(
                child: Center(
                  child: _isCountdownActive
                      ? _buildCountdownPanel()
                      : _buildConveyorSpinnerPanel(),
                ),
              ),

              const Divider(color: Colors.white12, height: 1),

              // BOTÓN INFERIOR DE ACCIÓN (SPLASH)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildSplashActionButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // PANEL CONVEYOR SPINNING
  // ==========================================
  Widget _buildConveyorSpinnerPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSpinning ? '¡RANDOMIZANDO RETOS!' : '¿Listos para tirar?',
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold, 
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        
        // 1. CINTA DE RETOS
        const Text('RETOS Y PENAS', style: TextStyle(fontSize: 10, color: Colors.white30, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        _buildConveyorBelt(
          controller: _challengeScrollController,
          items: _challengeSpinnerItems,
          itemWidth: _challengeItemWidth,
          height: 100,
          isDare: true,
        ),
        
        const SizedBox(height: 24),

        // 2. CINTA DE JUGADORES
        const Text('VÍCTIMA SELECCIONADA', style: TextStyle(fontSize: 10, color: Colors.white30, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        _buildConveyorBelt(
          controller: _playerScrollController,
          items: _playerSpinnerItems,
          itemWidth: _playerItemWidth,
          height: 60,
          isDare: false,
        ),
      ],
    );
  }

  Widget _buildConveyorBelt({
    required ScrollController controller,
    required List<String> items,
    required double itemWidth,
    required double height,
    required bool isDare,
  }) {
    return Center(
      child: Container(
        height: height,
        width: 320, // Ancho fijo para centrar y alinear los giros con precisión matemática
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white12, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
          ]
        ),
        child: Stack(
          children: [
            // El ListView horizontal
            ListView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(), // Controlado por el código
              itemCount: items.length,
              itemBuilder: (context, index) {
                final val = items[index];
                return Container(
                  width: itemWidth,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDare 
                        ? const Color(0xFF3E0A0A) 
                        : const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDare 
                          ? Colors.redAccent.withOpacity(0.3) 
                          : Colors.white12,
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    val,
                    maxLines: isDare ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isDare ? 12 : 14,
                      fontWeight: isDare ? FontWeight.normal : FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            
            // Punteros del medio (Marcador)
            Center(
              child: Container(
                width: itemWidth + 8,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFFC107), width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            // Flecha indicadora superior
            Align(
              alignment: Alignment.topCenter,
              child: Icon(Icons.arrow_drop_down, color: const Color(0xFFFFC107), size: 24),
            ),
            // Flecha indicadora inferior
            Align(
              alignment: Alignment.bottomCenter,
              child: Icon(Icons.arrow_drop_up, color: const Color(0xFFFFC107), size: 24),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PANEL TEMPORIZADOR COUTDOWN ACTIVO
  // ==========================================
  Widget _buildCountdownPanel() {
    final double progress = (_countdownDuration - _secondsLeft) / _countdownDuration;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.2),
            border: Border.all(color: Colors.white10),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Indicador circular de progreso
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: 1 - progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white12,
                  color: Colors.redAccent,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_empty, size: 28, color: Colors.white54),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(_secondsLeft),
                    style: const TextStyle(
                      fontSize: 36, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'RESTANTE',
                    style: TextStyle(fontSize: 10, color: Colors.white30, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  )
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Tensión en el ambiente...',
          style: TextStyle(
            fontSize: 16, 
            fontStyle: FontStyle.italic,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'El botón de SPLASH se desbloqueará al terminar.',
          style: TextStyle(fontSize: 12, color: Colors.white30),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ==========================================
  // BOTÓN SPLASH INTERACTIVO
  // ==========================================
  Widget _buildSplashActionButton() {
    if (_isCountdownActive) {
      // Estado deshabilitado / Cuenta atrás
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade700, width: 2),
        ),
        child: Center(
          child: Text(
            '¡SPLASH BLOQUEADO! (${_formatTime(_secondsLeft)})',
            style: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w900, 
              color: Colors.white38,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );
    }

    // Botón Activo
    return GestureDetector(
      onTap: _triggerSplash,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _isSpinning ? const Color(0xFFD32F2F) : const Color(0xFFFFC107),
          borderRadius: BorderRadius.circular(15),
          boxShadow: _isSpinning
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFFFFC107).withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  )
                ],
          border: Border.all(
            color: _isSpinning ? Colors.white24 : const Color(0xFFFFB300),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            _isSpinning ? '¡SPLASH!' : '¿SPLASH?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _isSpinning ? Colors.white : Colors.black,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// POPUP FLIP COIN CON FÍSICAS DE GIRO
// ==========================================
class CoinFlipDialog extends StatefulWidget {
  final String playerName;
  final Function(bool isSaved) onFlipFinished;

  const CoinFlipDialog({
    super.key,
    required this.playerName,
    required this.onFlipFinished,
  });

  @override
  State<CoinFlipDialog> createState() => _CoinFlipDialogState();
}

class _CoinFlipDialogState extends State<CoinFlipDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;
  late Animation<double> _heightAnimation;
  
  bool _isFlipping = false;
  bool _flipped = false;
  bool _resultSaved = false; // true = Salvado, false = X2

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Animación de rotación (múltiples giros de 360 grados)
    _flipAnimation = Tween<double>(begin: 0, end: 12 * math.pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutQuad),
    );

    // Animación de altura (subida y bajada de la moneda)
    _heightAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 2.2).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 2.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_animationController);

    // Lanzamiento automático al abrir el diálogo
    _startFlip();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startFlip() {
    setState(() {
      _isFlipping = true;
      _flipped = false;
      // 50% de probabilidad
      _resultSaved = math.Random().nextBool();
    });

    _animationController.forward().then((_) {
      if (mounted) {
        setState(() {
          _isFlipping = false;
          _flipped = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFFFFC107).withOpacity(0.3)),
        ),
        title: const Center(
          child: Text(
            'Lanzamiento de Moneda',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Jugador: ${widget.playerName}',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 30),
            
            // MONEDA ANIMADA
            SizedBox(
              height: 150,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  // Eje Y de rotación en 3D
                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Perspectiva
                    ..rotateY(_flipAnimation.value);

                  return Transform(
                    transform: transform,
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: _heightAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFF8F00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB300).withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                      border: Border.all(color: Colors.amber.shade200, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.star, 
                      size: 40, 
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // MOSTRAR RESULTADO
            if (_flipped) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _resultSaved 
                      ? Colors.green.withOpacity(0.15) 
                      : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _resultSaved ? Colors.green : Colors.red,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _resultSaved ? '¡SALVADO!' : '¡DUPLICADO!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _resultSaved ? Colors.greenAccent : Colors.redAccent,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _resultSaved
                          ? 'Pueblo recibe +1 chupito.\n¡Te libras por ahora!'
                          : 'Recibes +2 chupitos.\n¡Al suelo de cabeza!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'Lanzando al aire...',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white30),
              )
            ]
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: _flipped
            ? [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Cierra dialogo
                    widget.onFlipFinished(_resultSaved); // Activa el callback
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _resultSaved ? Colors.green : Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'ACEPTAR',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                )
              ]
            : [],
      ),
    );
  }
}
