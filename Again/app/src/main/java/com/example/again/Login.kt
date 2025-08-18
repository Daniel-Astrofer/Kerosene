package com.example.again

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asComposePath
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.ModifierLocalBeyondBoundsLayout
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.graphics.shapes.RoundedPolygon
import androidx.graphics.shapes.toPath
import androidx.navigation.NavController
import androidx.navigation.compose.rememberNavController
import java.nio.file.WatchEvent


@Composable
fun LoginScreen(navController: NavController){

    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center ){

        Background()

        CreateAccountBox(navController)

    }


}

@Composable
fun Background(){


    Box(){

        Image(modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop,painter = painterResource(id = R.drawable.olaaa), contentDescription = "estrela")

        Box(modifier = Modifier.fillMaxSize()){

            Box(
                modifier = Modifier
                    .drawWithCache {
                        val roundedPolygon = RoundedPolygon(
                            numVertices = 3,
                            radius = size.minDimension / 2,
                            centerX = size.width / 4,
                            centerY = size.height * 0.001f
                        )
                        val roundedPolygonPath = roundedPolygon.toPath().asComposePath()
                        onDrawBehind {
                            drawPath(roundedPolygonPath, color = Color.Blue)
                        }
                    }
                    .fillMaxSize()
            )

        }

        Box(modifier = Modifier
            .rotate(180f)
            .drawWithCache {
                val triangulo = RoundedPolygon(
                    numVertices = 3,
                    radius = size.minDimension / 2,
                    centerY = size.height * 0.001f,
                    centerX = size.width / 4
                )
                val trianguloPath = triangulo.toPath().asComposePath()
                onDrawBehind {
                    drawPath(trianguloPath, color = Color.Blue)
                }
            }
            .fillMaxSize())


        Box(modifier = Modifier
            .border(2.dp, color = Color.Black)
            .rotate(180f)
            .drawWithCache {
                val brush = Brush.horizontalGradient(listOf(Color.Blue,Color.Black))
                val triangulo = RoundedPolygon(
                    numVertices = 3,
                    radius = size.minDimension / 1,
                    centerY = size.height * 1f,
                    centerX = size.width *0.002f
                )
                val trianguloPath = triangulo.toPath().asComposePath()
                onDrawBehind {
                    drawPath(trianguloPath, brush = brush)
                }
            }
            .fillMaxSize())

        Box(modifier = Modifier
            .border(2.dp, color = Color.Black)
            .drawWithCache {
                val brush = Brush.horizontalGradient(listOf(Color.Blue,Color.Black))
                val triangulo = RoundedPolygon(
                    numVertices = 3,
                    radius = size.minDimension / 1,
                    centerY = size.height * 1.1f,
                    centerX = size.width /2
                )
                val trianguloPath = triangulo.toPath().asComposePath()
                onDrawBehind {
                    drawPath(trianguloPath, brush = brush)
                }
            }
            .fillMaxSize())

;


    }

}


@Composable
fun CreateAccountBox(navController: NavController){


    Box(modifier = Modifier
        .height(550.dp)
        .width(360.dp)
        .clip(shape = RoundedCornerShape(60.dp))
        .background(Color.Black),


        ){
        var rememberText by remember{ mutableStateOf("")}
        Text("Kerosene", modifier = Modifier.align(Alignment.TopCenter), textDecoration = TextDecoration.Underline, color = Color.Red, fontWeight = FontWeight.ExtraBold, fontSize = 40.sp)

        Box(modifier = Modifier.align(Alignment.Center)) {
            Column {
                Text("Usuário : ", fontSize = 19.sp, color = Color.LightGray)
                TextField(
                    value = rememberText,
                    onValueChange = {
                        rememberText = it },
                    label = {  })




            Column {
                Text("Frase de Segurança : ", fontSize = 19.sp, color = Color.LightGray)
                TextField(
                    value = rememberText,
                    onValueChange = {
                        rememberText = it },
                    label = {  })
            }
        }
        }



        Box(modifier = Modifier.align(Alignment.BottomCenter)){
            Row(){
                Button(onClick = {}) { Text("Entrar")}
                Button(onClick = {navController.navigate("Criar Conta")}) { Text("Não tenho Conta")}
            }
        }

    }

}

@Preview
@Composable
fun Presentation(){
    val navController = rememberNavController()

    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center ){

        Background()

        CreateAccountBox(navController)

    }


}