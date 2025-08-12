
    package com.example.again

    import android.annotation.SuppressLint

    import android.os.Bundle
    import androidx.activity.ComponentActivity
    import androidx.activity.compose.setContent
    import androidx.activity.enableEdgeToEdge
    import androidx.compose.foundation.ExperimentalFoundationApi
    import androidx.compose.foundation.background
    import androidx.compose.foundation.border
    import androidx.compose.foundation.clickable
    import androidx.compose.foundation.layout.Arrangement
    import androidx.compose.foundation.layout.Box
    import androidx.compose.material3.Icon
    import androidx.compose.foundation.layout.Column
    import androidx.compose.foundation.layout.Row
    import androidx.compose.foundation.layout.Spacer
    import androidx.compose.foundation.layout.fillMaxSize
    import androidx.compose.foundation.layout.fillMaxWidth
    import androidx.compose.foundation.layout.height
    import androidx.compose.foundation.layout.padding
    import androidx.compose.foundation.layout.requiredSize
    import androidx.compose.foundation.layout.size
    import androidx.compose.foundation.layout.width
    import androidx.compose.foundation.shape.CircleShape
    import androidx.compose.foundation.shape.CutCornerShape
    import androidx.compose.foundation.shape.RoundedCornerShape
    import androidx.compose.foundation.text.BasicSecureTextField
    import androidx.compose.foundation.text.KeyboardActions
    import androidx.compose.foundation.text.input.InputTransformation
    import androidx.compose.foundation.text.input.TextFieldState
    import androidx.compose.foundation.text.input.TextObfuscationMode
    import androidx.compose.foundation.text.input.maxLength
    import androidx.compose.foundation.text.input.rememberTextFieldState
    import androidx.compose.material.icons.Icons
    import androidx.compose.material.icons.filled.Star
    import androidx.compose.material.icons.filled.Warning
    import androidx.compose.material3.Button
    import androidx.compose.material3.FilledTonalButton
    import androidx.compose.material3.Icon
    import androidx.compose.material3.MaterialTheme.shapes
    import androidx.compose.material3.OutlinedButton

    import androidx.compose.material3.Surface
    import androidx.compose.material3.Text
    import androidx.compose.material3.TextField
    import androidx.compose.material3.TextFieldDefaults
    import androidx.compose.runtime.Composable
    import androidx.compose.runtime.MutableState
    import androidx.compose.runtime.collectAsState
    import androidx.compose.runtime.getValue
    import androidx.compose.runtime.mutableStateOf
    import androidx.compose.runtime.remember
    import androidx.compose.runtime.saveable.rememberSaveable
    import androidx.compose.runtime.setValue
    import androidx.compose.ui.Alignment
    import androidx.compose.ui.Modifier
    import androidx.compose.ui.draw.clip
    import androidx.compose.ui.graphics.Color
    import androidx.compose.ui.graphics.Shape
    import androidx.compose.ui.text.font.FontStyle
    import androidx.compose.ui.text.font.FontWeight
    import androidx.compose.ui.text.style.TextAlign
    import androidx.compose.ui.text.style.TextDecoration
    import androidx.compose.ui.unit.dp
    import androidx.compose.ui.unit.max
    import androidx.compose.ui.unit.sp
    import androidx.lifecycle.ViewModel
    import androidx.lifecycle.viewmodel.compose.viewModel
    import androidx.media3.extractor.text.webvtt.WebvttCssStyle
    import androidx.navigation.NavController
    import com.example.again.ui.theme.AgainTheme
    import com.google.common.util.concurrent.ClosingFuture.submit




    @Composable
    fun LoginScreen(navController: NavController){

        Column(modifier = Modifier
            .fillMaxSize()
            ,
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally)
        {
            BoxLogin(navController)
        }
    }

    @Composable
    fun BoxLogin(navController: NavController){
        var rememberText by remember{mutableStateOf("")}
        var rememberPass by remember{mutableStateOf("")}
        var submitAttemptedE by remember{mutableStateOf(false)}


        Surface(modifier = Modifier.padding(20.dp).size(500.dp))
        {


            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center)
            {

                Text("Kerosene", fontSize = 39.sp, fontWeight = FontWeight.Bold)
                Spacer(Modifier.padding(bottom = 16.dp))

                TextField(
                    value = rememberText,
                    maxLines = 1,
                    keyboardActions = KeyboardActions.Default,
                    onValueChange = {
                        rememberText = it

                    },
                    shape = RoundedCornerShape(30.dp),
                    colors = TextFieldDefaults.colors(unfocusedIndicatorColor = Color.Transparent, focusedIndicatorColor = Color.Transparent),
                    label = { Text("Email") })

                    Column(modifier = Modifier.fillMaxWidth()){

                        EmailError(submitAttemptedE, rememberText)

                    }

                Spacer(Modifier.padding(23.dp))


                TextField(
                    value = rememberPass,
                    maxLines = 1,
                    keyboardActions = KeyboardActions.Default,
                    onValueChange = {
                        rememberPass= it

                    },
                    shape = RoundedCornerShape(30.dp),
                    colors = TextFieldDefaults.colors(unfocusedIndicatorColor = Color.Transparent, focusedIndicatorColor = Color.Transparent),
                    label = { Text("Senha") })

                Column(modifier = Modifier.fillMaxWidth()){

                    PassError(submitAttemptedE, rememberPass)

                }


                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                    modifier = Modifier.padding(20.dp)
                ) {


                    Spacer(modifier = Modifier.height(24.dp)) // espaço entre campos e botões

                    Row(
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedButton(onClick = {

                        }) {
                            Text("Sign Up")
                        }


                        Button(onClick = {
                            submitAttemptedE = true
                            if (Verify(rememberText, rememberPass)){
                            navController.navigate("second")}

                        }) {
                            Text("Login")
                        }

                    }
                }


            }


        }















    }
    @Composable
    fun EmailError(submitAtempt : Boolean , email : String){
        if (submitAtempt && !VerifyE(email) ) {
            Column {
                Text(
                    "email inválido",
                    textDecoration = TextDecoration.Underline,
                    modifier = Modifier.align (Alignment.Start).padding(start = 60.dp),
                    color = Color.Red
                )


            }
        }

    }

    @Composable
    fun PassError(submitAtemptP : Boolean , pass : String){
        if (submitAtemptP && !VerifyP(pass) ) {
            Column {
                Text(
                    "senha inválida",
                    textDecoration = TextDecoration.Underline,
                    modifier = Modifier.align (Alignment.Start).padding(start = 60.dp),
                    color = Color.Red
                )


            }
        }

    }




    @Composable
    fun PasswordTextField(state: String) {
        val state = TextFieldState(state)
        var showPassword by remember { mutableStateOf(false) }
        BasicSecureTextField(

            state = state,
            textObfuscationMode =
                if (showPassword) {
                    TextObfuscationMode.Visible
                } else {
                    TextObfuscationMode.RevealLastTyped
                },
            modifier = Modifier
                .width(290.dp)
                .padding(6.dp)
                .border(1.dp, Color.LightGray, RoundedCornerShape(30.dp))
                .padding(6.dp)
                ,
            decorator = { innerTextField ->
                Box(
                    modifier = Modifier.width(100.dp)) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.CenterStart)
                            .padding(start = 16.dp, end = 48.dp)
                    ) {
                        innerTextField()
                    }
                    Icon(
                        if (showPassword) {
                            Icons.Filled.Warning
                        } else {
                            Icons.Filled.Star
                        },
                        contentDescription = "Toggle password visibility",
                        modifier = Modifier
                            .align(Alignment.CenterEnd)
                            .requiredSize(48.dp).padding(16.dp)
                            .clickable { showPassword = !showPassword }
                    )
                }
            }
        )
    }
