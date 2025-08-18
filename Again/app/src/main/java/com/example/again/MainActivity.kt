package com.example.again


import android.os.Build
import android.os.Bundle
import android.view.WindowInsets
import android.view.WindowInsetsController
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.annotation.RequiresApi
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.core.view.WindowCompat

import com.example.again.ui.theme.AgainTheme
import com.google.accompanist.systemuicontroller.rememberSystemUiController


class MainActivity : ComponentActivity() {
    @RequiresApi(Build.VERSION_CODES.R)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)


        enableEdgeToEdge()
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.insetsController?.let { controller ->
            controller.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
            controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
        setContent {
            AgainTheme {
                AppNavigation()
            }
        }
    }
}

@Composable
fun FullScreenContent() {
    val systemUiController = rememberSystemUiController()

    SideEffect {
        systemUiController.isStatusBarVisible = false
        systemUiController.isNavigationBarVisible = false
    }
    AppNavigation()
}


