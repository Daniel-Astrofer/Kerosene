    package com.example.again

    import androidx.compose.runtime.Composable
    import androidx.lifecycle.viewmodel.compose.viewModel
    import androidx.navigation.NavHost
    import androidx.navigation.Navigator
    import androidx.navigation.compose.NavHost
    import androidx.navigation.compose.composable
    import androidx.navigation.compose.rememberNavController



    @Composable
    fun AppNavigation(){
        val navController = rememberNavController()

        NavHost(navController, startDestination = "initialize") {
            composable("initialize") { Presentation(navController) }
            composable("Criar Conta") { CreatingAccount(navController) }
            composable("main") { Screen(navController) }

        }
        /*if (lastLogged){

            NavHost(navController, startDestination = "main"){

                composable("main"){Screen(navController)}

            }



        }else {


        }*/
    }