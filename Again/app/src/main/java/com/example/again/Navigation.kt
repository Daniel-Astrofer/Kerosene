package com.example.again

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController



@Composable
fun AppNavigation(){
    val navController = rememberNavController()

    NavHost(navController, startDestination = "main"){
        composable("main"){ Main(navController) }
        composable("second"){ LoginScreen(navController) }
    }
}