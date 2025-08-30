import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/usuario.dart';
import 'screens/aguardando_aprovacao_screen.dart';
import 'screens/cadastro_usuario_screen.dart';
import 'screens/gerenciar_usuarios_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_home_screen.dart';
import 'screens/regionais_screen.dart';
import 'screens/regional_home_screen.dart';
import 'services/auth_service.dart';
import 'services/regional_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Relatório de Pagamento',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1976D2), // Azul principal
          secondary: Color(0xFF03DAC6), // Verde água
          surface: Color(0xFFFAFAFA), // Fundo claro
          error: Color(0xFFB00020), // Vermelho para erros
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Color(0xFF1C1B1F),
          onError: Colors.white,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/cadastro': (context) => const CadastroUsuarioScreen(),
        '/gerenciar-usuarios': (context) => const GerenciarUsuariosScreen(),
        '/regionais': (context) => const RegionaisScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final RegionalService _regionalService = RegionalService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Mostrar loading enquanto verifica autenticação
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Se não há usuário logado, mostrar tela de login
        if (snapshot.data == null) {
          return const LoginScreen();
        }

        // Se há usuário logado, verificar status e navegar adequadamente
        return FutureBuilder<Usuario?>(
          future: _authService.getUsuarioAtual(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final usuario = userSnapshot.data;
            if (usuario == null) {
              return const LoginScreen();
            }

            // Navegar conforme status do usuário
            switch (usuario.statusAprovacao) {
              case StatusAprovacao.aguardando:
                return const AguardandoAprovacaoScreen();
              case StatusAprovacao.aprovado:
                return _navegarParaTelaPrincipal(usuario);
              case StatusAprovacao.rejeitado:
                return const LoginScreen();
            }
          },
        );
      },
    );
  }

  Widget _navegarParaTelaPrincipal(Usuario usuario) {
    switch (usuario.tipoUsuario) {
      case TipoUsuario.gcote:
        return MainHomeScreen();
      case TipoUsuario.chefeUniae:
      case TipoUsuario.administrativoUniae:
        if (usuario.regionalId != null) {
          return FutureBuilder(
            future: _regionalService.getRegionalById(usuario.regionalId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final regional = snapshot.data;
              if (regional != null) {
                return RegionalHomeScreen(regional: regional);
              } else {
                // Fallback se não encontrar a regional
                return MainHomeScreen();
              }
            },
          );
        } else {
          // Fallback se não tiver regionalId
          return MainHomeScreen();
        }
    }
  }
}
