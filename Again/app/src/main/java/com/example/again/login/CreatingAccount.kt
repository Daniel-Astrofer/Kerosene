package com.example.again.login

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asComposePath
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.graphics.shapes.RoundedPolygon
import androidx.graphics.shapes.toPath
import androidx.navigation.NavController
import androidx.navigation.compose.rememberNavController
import com.example.again.R
import com.example.again.api.RetrofitClient
import com.example.again.api.gerarFraseBip39
import com.example.again.api.hash
import com.example.again.api.model.Usuario
import kotlinx.coroutines.launch
import okhttp3.Callback
import retrofit2.Response
import java.net.ConnectException
import java.net.UnknownHostException

data class Usuario(
    val id: Long = 0,
    val username: String,
    val passphrase: String,
    val fingertip: String = "",
    val creation_date: String = ""
)

val paleta1 = Color(0xFF11202B)
val paleta2 = Color(0xFF1F2A33)
val ggsans = FontFamily(
    Font(R.font.ggsanssemibold, FontWeight.SemiBold)
)
val buttoncolor = Color(0xFF1F6299)
val poppins = FontFamily(
    Font(R.font.poppins_semibold, FontWeight.SemiBold)
)
val inter = FontFamily(
    Font(R.font.inter_18pt_black, FontWeight.SemiBold)
)

@Composable
fun CreatingAccount(navController: NavController) {
    Box(modifier = Modifier
        .fillMaxSize()
        .background(paleta1)
        .padding(start = 30.dp)) {

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = 30.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        )
        {
            BoxLogin(navController)
        }
        Box(
            modifier = Modifier.clip(RoundedCornerShape(bottomEnd = 20.dp)).background(paleta2)
        ) {
            IconButton(
                onClick = {}
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Voltar",
                    tint = Color.White,
                    modifier = Modifier.align(Alignment.TopStart).size(60.dp)
                )
            }
        }
        BoxWithConstraints(
            modifier = Modifier
                .clickable {
                }
                .align(Alignment.BottomEnd)
                .drawWithCache {
                    val sizebutton = size.minDimension * 2f
                    val centerY = size.height / 2f
                    val centerX = size.width / 2f
                    val roundedPolygon = RoundedPolygon(
                        numVertices = 3,
                        radius = sizebutton,
                        centerX = centerX,
                        centerY = centerY
                    )
                    val roundedPolygonPath = roundedPolygon.toPath().asComposePath()
                    onDrawBehind {
                        rotate(
                            45f,
                            Offset(centerX, centerY),
                            block = { drawPath(roundedPolygonPath, color = buttoncolor) }
                        )
                    }
                },
            contentAlignment = Alignment.BottomCenter
        ){
            val size = this
            Icon(imageVector = Icons.AutoMirrored.Filled.ArrowForward, contentDescription = "Prosseguir", modifier = Modifier.size(120.dp), tint = Color.White)
        }
    }
}

@Composable
fun BoxLogin(navController: NavController) {
    var username by remember { mutableStateOf("") }
    var passPhrasse by remember { mutableStateOf("") }
    var message by remember { mutableStateOf("") }

    val coroutineScope = rememberCoroutineScope()
    val frase = gerarFraseBip39()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(top = 20.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text("Crie sua Conta", color = Color.LightGray, fontSize = 30.sp, fontFamily = poppins)
            Spacer(modifier = Modifier.padding(bottom = 30.dp))
            Text("Nome de usuário :", color = Color.LightGray, fontSize = 17.sp, fontFamily = ggsans)
            TextField(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                label = { Text("Usuário", color = Color.LightGray, fontFamily = ggsans) },
                value = username,
                onValueChange = { username = it },
                colors = TextFieldDefaults.colors(unfocusedContainerColor = Color.DarkGray),
                shape = RoundedCornerShape(0.dp)
            )

            Spacer(modifier = Modifier.padding(top = 30.dp))
            Text("Frase de Login :", color = Color.LightGray, fontFamily = ggsans, fontSize = 17.sp)

            TextField(
                value = frase,
                onValueChange = { passPhrasse = it },
                maxLines = 1,
                label = {  },
                modifier = Modifier.fillMaxWidth(),
                colors = TextFieldDefaults.colors(unfocusedContainerColor = Color.DarkGray),
                readOnly = false,
                shape = RoundedCornerShape(0.dp)
            )

            Spacer(modifier = Modifier.padding(top = 20.dp))

            Button(onClick = {
                val usuario = Usuario(username, frase )

                // Chamada assíncrona
                RetrofitClient.instance.createUser(usuario).enqueue(object : retrofit2.Callback<Usuario> {
                    override fun onResponse(call: retrofit2.Call<Usuario>, response: retrofit2.Response<Usuario>) {
                        message = if (response.isSuccessful) {
                            "Usuário criado com sucesso: ${response.body()?.username}"
                        } else {
                            "Erro: ${response.code()}"
                        }
                    }

                    override fun onFailure(call: retrofit2.Call<Usuario>, t: Throwable) {
                        message = "Falha na requisição: ${t.localizedMessage}"
                    }
                })


            }) {
                Text("clica")
            }

            if (message.isNotEmpty()) {
                Text(message, color = Color.White, modifier = Modifier.padding(top = 10.dp))
            }



        }
    }
}

@Preview
@Composable
fun CreatingAccoun(){
    val navController = rememberNavController()
    Box(modifier = Modifier
        .fillMaxSize()
        .padding(top = 30.dp)
        .background(paleta1)) {

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = 30.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        )
        {
            BoxLogin(navController)
        }
        Box(
            modifier = Modifier.clip(RoundedCornerShape(bottomEnd = 20.dp)).background(paleta2)
        ) {
            IconButton(
                onClick = {}
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Voltar",
                    tint = Color.White,
                    modifier = Modifier.align(Alignment.TopStart).size(60.dp)
                )
            }
        }
        BoxWithConstraints(
            modifier = Modifier
                .clickable {
                }
                .align(Alignment.BottomEnd)
                .drawWithCache {
                    val sizebutton = size.minDimension * 2f
                    val centerY = size.height / 2f
                    val centerX = size.width / 2f
                    val roundedPolygon = RoundedPolygon(
                        numVertices = 3,
                        radius = sizebutton,
                        centerX = centerX,
                        centerY = centerY
                    )
                    val roundedPolygonPath = roundedPolygon.toPath().asComposePath()
                    onDrawBehind {
                        rotate(
                            45f,
                            Offset(centerX, centerY),
                            block = { drawPath(roundedPolygonPath, color = buttoncolor) }
                        )
                    }
                },
            contentAlignment = Alignment.BottomCenter
        ){
            val size = this
            Icon(imageVector = Icons.AutoMirrored.Filled.ArrowForward, contentDescription = "Prosseguir", modifier = Modifier.size(120.dp), tint = Color.White)
        }
    }
}

@Composable
fun CriarUsuarioScreen() {
    var username by remember { mutableStateOf("") }
    var passphrase by remember { mutableStateOf("") }
    var message by remember { mutableStateOf("") }

    val coroutineScope = rememberCoroutineScope()

    Column {
        OutlinedTextField(
            value = username,
            onValueChange = { username = it },
            label = { Text("Username") }
        )
        OutlinedTextField(
            value = passphrase,
            onValueChange = { passphrase = it },
            label = { Text("Passphrase") }
        )

        Button(onClick = {
            coroutineScope.launch {
                try {
                    val usuario = Usuario(username, passphrase)
                    val response = RetrofitClient.instance.createUser(usuario)
                    message = "Usuário criado com id: ${response.request()}"
                } catch (e: Exception) {
                    message = "Erro: ${e.localizedMessage ?: "Erro desconhecido"}"
                }
            }
        }) {
            Text("Criar Usuário")
        }
        Text(text = message)
    }
}

@Preview(showBackground = true)
@Composable
fun PreviewCriarUsuarioScreen() {
    CriarUsuarioScreen()
}

