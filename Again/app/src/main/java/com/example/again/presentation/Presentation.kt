package com.example.again.presentation

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.example.again.R


@Composable
fun Presentation(navController: NavController){

    val paleta2 = Color(0xFF294A66)
    val paleta3 = Color(0xFF1F2A33)
    val paleta4 = Color(0xFF1F6299)
    val paleta6 = Color(0xFF0B73C7)

    val poppins = FontFamily(

        Font(R.font.nunito_medium, FontWeight.Medium)


    )
    val inter = FontFamily(
        Font(R.font.inter_18pt_black, FontWeight.SemiBold)
    )


    BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
        val size = this

        Image(modifier = Modifier.fillMaxSize(),painter = painterResource(id = R.drawable.space), contentDescription = "Background", contentScale = ContentScale.FillHeight)

        Box(modifier = Modifier.matchParentSize().background(brush = Brush.verticalGradient(listOf(Color.Transparent, Color.Black), startY = 800f)))
        Box(modifier = Modifier.align(Alignment.CenterStart).padding(start = 40.dp)) {
            Column {
                Text(
                    "Kerosene",
                    fontFamily = inter,
                    fontSize = 45.sp,
                    color = Color.White,

                    )
                Text(
                    "A Real Privacidade e Segurança.",
                    fontFamily = poppins,
                    fontSize = 15.sp,
                    color = Color.White,

                    )
            }
        }
        Box(modifier = Modifier.align(Alignment.BottomCenter  )){
            Column(modifier = Modifier.padding(bottom = 100.dp)) {

                Button(
                    modifier = Modifier
                        .width(300.dp)
                        .shadow(30.dp, spotColor = paleta6, shape = RoundedCornerShape(10.dp)),

                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(paleta2),
                    onClick = { navController.navigate("Criar Conta") }

                )
                { Text(
                        "Criar Conta",
                        fontFamily = poppins,
                        fontSize = 17.sp)
                }
                Button(
                    onClick = {



                    },
                    colors = ButtonDefaults.buttonColors(paleta3),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier.width(300.dp)
                ) { Text("Entrar", fontFamily = poppins, fontSize = 17.sp) }
            }
        }

    }



}