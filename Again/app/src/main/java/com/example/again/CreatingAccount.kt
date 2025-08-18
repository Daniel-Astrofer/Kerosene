
    package com.example.again

    import android.R.attr.shape
    import androidx.compose.foundation.Image
    import androidx.compose.foundation.background
    import androidx.compose.foundation.clickable
    import androidx.compose.foundation.layout.Arrangement
    import androidx.compose.foundation.layout.Box
    import androidx.compose.foundation.layout.BoxWithConstraints
    import androidx.compose.foundation.layout.Column
    import androidx.compose.foundation.layout.Spacer
    import androidx.compose.foundation.layout.fillMaxSize
    import androidx.compose.foundation.layout.fillMaxWidth
    import androidx.compose.foundation.layout.height
    import androidx.compose.foundation.layout.offset
    import androidx.compose.foundation.layout.padding
    import androidx.compose.foundation.layout.size
    import androidx.compose.foundation.shape.RoundedCornerShape
    import androidx.compose.material.icons.Icons
    import androidx.compose.material.icons.automirrored.filled.ArrowBack
    import androidx.compose.material.icons.automirrored.filled.ArrowForward
    import androidx.compose.material.icons.rounded.ArrowBack
    import androidx.compose.material3.Icon
    import androidx.compose.material3.IconButton
    import androidx.compose.material3.Text
    import androidx.compose.material3.TextField
    import androidx.compose.material3.TextFieldDefaults
    import androidx.compose.runtime.Composable
    import androidx.compose.runtime.getValue
    import androidx.compose.runtime.mutableStateOf
    import androidx.compose.runtime.remember
    import androidx.compose.runtime.setValue
    import androidx.compose.ui.Alignment
    import androidx.compose.ui.Modifier
    import androidx.compose.ui.draw.clip
    import androidx.compose.ui.draw.drawBehind
    import androidx.compose.ui.draw.drawWithCache
    import androidx.compose.ui.draw.drawWithContent
    import androidx.compose.ui.draw.rotate
    import androidx.compose.ui.geometry.Offset
    import androidx.compose.ui.graphics.Color
    import androidx.compose.ui.graphics.asComposePath
    import androidx.compose.ui.graphics.drawscope.rotate
    import androidx.compose.ui.layout.ContentScale
    import androidx.compose.ui.res.painterResource
    import androidx.compose.ui.text.font.Font
    import androidx.compose.ui.text.font.FontFamily
    import androidx.compose.ui.text.font.FontWeight
    import androidx.compose.ui.text.style.LineHeightStyle
    import androidx.compose.ui.tooling.preview.Preview
    import androidx.compose.ui.unit.dp
    import androidx.compose.ui.unit.sp
    import androidx.graphics.shapes.RoundedPolygon
    import androidx.graphics.shapes.toPath
    import androidx.navigation.NavController
    import androidx.navigation.compose.rememberNavController

    val  paleta1= Color(0xFF11202B)
    val paleta2 = Color(0xFF1F2A33)
    val ggsans = FontFamily(
        Font(R.font.ggsanssemibold, FontWeight.SemiBold)


    )

    val buttoncolor = Color(0xFF0B73C7)
    @Composable
    fun CreatingAccount(navController: NavController){

        Box(modifier = Modifier
            .fillMaxSize()
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
            IconButton(
                onClick = {}
            ) {
                Icon(imageVector = Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Voltar", tint = Color.White, modifier = Modifier.align(Alignment.TopStart) )
            }
        }
    }

    @Composable
    fun BoxLogin(navController: NavController){
        var rememberText by remember{mutableStateOf("")}
        var rememberPass by remember{mutableStateOf("")}
        var submitAttemptedE by remember{mutableStateOf(false)}

        val poppins = FontFamily(

            Font(com.example.again.R.font.poppins_semibold, FontWeight.SemiBold)


        )
        val inter = FontFamily(
            Font(com.example.again.R.font.inter_18pt_black, FontWeight.SemiBold)
        )



        BoxWithConstraints {
            val size = this
            var passPhrasse by remember { mutableStateOf("") }

            Column(modifier = Modifier
                .fillMaxSize()
                .padding(top = 20.dp)) {
                Text("Crie sua Conta", color = Color.LightGray, fontSize = 30.sp, fontFamily = poppins , modifier = Modifier.align(
                    Alignment.CenterHorizontally))
                Spacer(modifier = Modifier.padding(bottom = 30.dp))
                Text("Nome de usuário :", color = Color.LightGray, fontSize = 17.sp, fontFamily = ggsans, modifier = Modifier
                    .align(Alignment.CenterHorizontally)
                    .padding(bottom = 15.dp) )
                TextField(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp)
                        ,
                    label = {Text("Usuário", color = Color.LightGray, fontFamily = ggsans)},
                    value = rememberText,
                    onValueChange = {rememberText = it},
                    colors = TextFieldDefaults.colors(unfocusedContainerColor = Color.DarkGray),
                    shape = RoundedCornerShape(0.dp)

                )

                Text("Frase de Login :", color = Color.LightGray, fontFamily = ggsans, fontSize = 17.sp, modifier = Modifier
                    .align(Alignment.CenterHorizontally)
                    .padding(top = 30.dp, bottom = 15.dp ))

                TextField(value = passPhrasse,
                    onValueChange = {passPhrasse = it},
                    label = {Text("casaco pista tigela roxo planeta minuto jovem salto febre solo livro chave", color = Color.Black, fontFamily = ggsans)},
                    modifier = Modifier.fillMaxWidth(),
                    colors = TextFieldDefaults.colors(unfocusedContainerColor = Color.DarkGray),
                    readOnly = true,
                    shape = RoundedCornerShape(0.dp))

                Text("Impressão Digital : ", fontSize = 17.sp, color = Color.LightGray, fontFamily = ggsans, modifier = Modifier.align(Alignment.CenterHorizontally).padding(top = 30.dp, bottom = 15.dp))
                TextField(value = passPhrasse,
                    label = {
                    Image(
                        painter = painterResource(id = R.drawable.impresao),
                        contentDescription = "Impressao digital",
                        modifier = Modifier.size(50.dp)
                    )
                }, onValueChange = {passPhrasse = it},
                    modifier = Modifier.fillMaxWidth().align(Alignment.CenterHorizontally),
                    colors = TextFieldDefaults.colors(unfocusedContainerColor = Color.DarkGray))



            }


        }


    }


    @Preview
    @Composable
    fun CreatingAccoun(){
        val navController = rememberNavController()


        Box(modifier = Modifier
            .fillMaxSize()
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
                        .b
                        .drawWithCache {
                            val sizebutton = size.minDimension
                            val centerY = size.height * 1f
                            val centerX = size.width
                            val roundedPolygon = RoundedPolygon(
                                numVertices = 3,
                                radius = sizebutton,
                                centerX = centerX,
                                centerY = centerY
                            )
                            val roundedPolygonPath = roundedPolygon.toPath().asComposePath()
                            onDrawBehind {
                                rotate(
                                    40f,
                                    Offset(centerX, centerY),
                                    block = { drawPath(roundedPolygonPath, color = buttoncolor) }

                                )

                            }
                        }
                        .fillMaxSize()
                ){
                    val size = this
                    Icon(imageVector = Icons.AutoMirrored.Filled.ArrowForward, contentDescription = "Prosseguir", modifier = Modifier.size(120.dp).offset(
                        x = (size.maxWidth / 3f) , y = (size.maxHeight / 2.5f)
                    ))
                }


            }


    }
