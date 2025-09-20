package com.example.again.navigation

    import androidx.compose.runtime.Composable
    import androidx.navigation.compose.NavHost
    import androidx.navigation.compose.composable
    import androidx.navigation.compose.rememberNavController
    import com.example.again.login.CreatingAccount
    import com.example.again.main.Screen
    import com.example.again.presentation.LoginScreen
    import com.example.again.presentation.Presentation


    @Composable
    fun AppNavigation(){
        val navController = rememberNavController()

        NavHost(navController, startDestination = "initialize") {
            composable("initialize") { Presentation(navController) }
            composable("Criar Conta") { CreatingAccount(navController) }
            composable("main") { Screen(navController) }
            composable("login"){ LoginScreen(navController) }

        }

    }