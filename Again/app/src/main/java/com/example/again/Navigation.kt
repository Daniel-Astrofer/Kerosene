    package com.example.again

    import androidx.compose.runtime.Composable
    import androidx.lifecycle.viewmodel.compose.viewModel
    import androidx.navigation.compose.NavHost
    import androidx.navigation.compose.composable
    import androidx.navigation.compose.rememberNavController



    @Composable
    fun AppNavigation(){
        val navController = rememberNavController()

        NavHost(navController, startDestination = "main"){
            composable("main"){ LoginScreen(navController) }
            composable("second"){ Main(navController) }
        }
    }