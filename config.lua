Config = {}

Config.Halloween = {
    ExitCommand = "salirhalloween",
    Debug = false,
    Inventory = 'vrp',
    Notify = 'vrp',
    InteractiveKey = 38,
    GlobalCooldown = 180,

    -- Sistema de Notificações
    Notifications = {
        Type = 'custom',
        GlobalAnnouncement = false,
        SilentItemGive = false,
        ShowItemReceived = true, -- Mostrar item recebido
        Messages = {
            GhostReward = "¡Encontraste un fantasma! Recibiste recompensas",
            PumpkinReward = "¡Calabaza premiada! Obtuviste golosinas",
            CompletedGhosts = "¡FELICIDADES! Completaste la Caza de Fantasmas",
            CompletedPumpkins = "¡INCREÍBLE! Completaste la Caza de Calabazas"
        }
    },

    ZombieModels = {
        `u_m_y_zombie_01`,
        `u_m_o_filmnoir`
    },

    ZombieAudios = {
        [1] = 'fast',
        [2] = 'tanque',
        [3] = 'frost',
        [4] = 'explosive'
    },

    LegionPark = {
        Graveyard = {
            Coords = vector3(230.44, -881.90, 30.49),
            Link = 'https://youtu.be/70HCGgKog_U?si=KqzZ0an05kVLaCPg',
            Volume = 0.1,
            Range = 20.0
        },
        BigPumpKin = {
            Coords = vector3(181.20, -969.70, 29.78),
            Link = 'https://youtu.be/70HCGgKog_U?si=KqzZ0an05kVLaCPg',
            Volume = 0.1,
            Range = 20.0
        }
    },

    Mission = {
        Enable = false,
        StartCoords = vector4(0.0, 0.0, 0.0, 0.0),
        Blip = {
            Enable = false
        },
        Rewards = {
            Enable = false,
            Items = {},
            Money = 0
        },
        Volume = {
            Music = 0.5,
            Voice = 0.5,
            Ghost = 0.5
        },
        Weprequired = "WEAPON_FLASHLIGHT",
        Cooldown = 60
    },

    GhostHunt = {
        Enable = true,
        NPC = {
            Model = `u_m_y_zombie_01`,
            Coords = vector4(221.65, -862.90, 29.29, 346.75)
        },
        NightSpawn = false,
        SpawnStartHour = 17,
        SpawnEndHour = 6,
        PhotoCommand = "tomarfoto",
        GhostModel = `m23_1_prop_m31_ghostjohnny_01a`,
        RequireVisible = false,
        Blip = {
            Enable = true,
            Sprite = 362,
            Color = 1,
            Name = "Misiones de Halloween",
            Scale = 1.0
        },
        
        Rewards = {
            Enable = true,
            Items = {
                ['catcookie'] = {amount = 3, chance = 15},
                ['agua'] = {amount = 3, chance = 15},
                ['chocolate'] = {amount = 3, chance = 10},
                ['coca'] = {amount = 3, chance = 10},
                ['cupcake'] = {amount = 3, chance = 10},
                ['energetico'] = {amount = 3, chance = 10},
                ['milkshakechocolate'] = {amount = 3, chance = 8},
                ['antibiotico'] = {amount = 3, chance = 8},
                ['jeringa'] = {amount = 3, chance = 9},
                ['ticketplaca'] = {amount = 1, chance = 2},
                ['c4'] = {amount = 2, chance = 3},
                ['dinheirosujer'] = {amount = 15000, chance = 1},
            },
            Money = 5000,
        },
        
        CompletionReward = {
            Enable = true,
            Vehicle = 'mx5halloween',
            Message = '¡INCREÍBLE! Completaste la Caza de Fantasmas. Habla con el NPC para recoger tu premio: mx5halloween'
        },
        
        GhostsLocation = {
            [1] =  vector4(451.05, -855.33, 27.30, 90.00),
            [2] =  vector4(315.33, -684.68, 29.07, -66.00),
            [3] =  vector4(64.78, -752.3457, 30.70, 210.00),
            [4] =  vector4(-210.53, -1206.36, 29.42, 150.00),
            [5] =  vector4(13.98, -1113.59, 37.15, 206.00),
            [6] =  vector4(-151.44, -160.35, 42.66, 308.00),
            [7] =  vector4(-356.25, -108.30, 37.87, 349.00),
            [8] =  vector4(-665.92, -720.71, 26.05, 81.00),
            [9] =  vector4(-714.06, -886.54, 22.86, -161.00),
            [10] = vector4(304.71, -1160.97, 28.27, 48.00),
            [11] = vector4(1541.81, 787.80, 76.94, 320.00),
            [12] = vector4(2544.34, 2607.39, 37.01, 203.00),
            [13] = vector4(2355.17, 3063.78, 47.40, 174.00),
            [14] = vector4(2040.63, 3189.22, 44.30, 149.00),
            [15] = vector4(1900.65, 3285.70, 45.07, 135.00),
            [16] = vector4(1693.07, 3596.14, 34.71, 210.00),
            [17] = vector4(1739.47, 3700.77, 33.17, 66.00),
            [18] = vector4(1609.22, 3784.84, 33.67, 38.00),
            [19] = vector4(1961.16, 3826.32, 31.16, 304.00),
            [20] = vector4(2147.26, 3919.21, 30.17, 337.42)
        }
    },

    PumpkinHunt = {
        Enable = true,
        RewardType = "item",
        
        VisualEffects = {
            Enable = true,
            
            Marker = {
                Enable = true,
                Type = 2,
                Size = vector3(0.3, 0.3, 1.2), -- REDUZIDO
                Color = {r = 255, g = 140, b = 0, a = 200},
                BobUpAndDown = true,
                Rotate = true,
                Distance = 30.0
            },
            
            SmokeEffect = {
                Enable = true,
                Asset = "core",
                Effect = "exp_grd_bzgas_smoke",
                Scale = 0.8,
                Color = {r = 50, g = 50, b = 50},
                Distance = 50.0
            },
            
            Light = {
                Enable = true,
                Color = {r = 255, g = 140, b = 0},
                Range = 4.0,
                Intensity = 1.5
            }
        },
        
        Audio = {
            OpenPumpkin = "https://files.fivemerr.com/audios/284d2437-4fbb-4c57-a43f-209cd78cd5f8.ogg",
            ScaryNPC = "https://youtu.be/Ox7JOd1YMPg?si=1AqfU9XagTfVpKDS",
            Volume = 1.0
        },
        
        TreatChance = 70,
        
        Rewards = {
            Enable = true,
            Items = {
                ['catcookie'] = {amount = 3, chance = 15},
                ['agua'] = {amount = 3, chance = 15},
                ['chocolate'] = {amount = 3, chance = 10},
                ['coca'] = {amount = 3, chance = 10},
                ['cupcake'] = {amount = 3, chance = 10},
                ['energetico'] = {amount = 3, chance = 10},
                ['milkshakechocolate'] = {amount = 3, chance = 8},
                ['antibiotico'] = {amount = 3, chance = 8},
                ['jeringa'] = {amount = 3, chance = 9},
                ['ticketplaca'] = {amount = 1, chance = 2},
                ['c4'] = {amount = 2, chance = 2},
                ['dinheirosujer'] = {amount = 15000, chance = 1},
            },
            Money = 5000,
        },
        
        CompletionReward = {
            Enable = true,
            Vehicle = 'mx5halloween',
            Message = '¡INCREÍBLE! Completaste la Caza de Calabazas. Habla con el NPC para recoger tu premio: mx5halloween'
        },
        
        Model = `ayc_hpumpkin`,
        
        -- COORDENADAS CORRIGIDAS COM Z AJUSTADO
        Location = {
            [1] = vector4(309.12, -911.39, 29.29, 63.35),
            [2] = vector4(334.07, -951.19, 29.29, 156.42),
            [3] = vector4(150.87, -1062.86, 29.29, 120.66),
            [4] = vector4(40.34, -952.62, 29.29, 160.74),
            [5] = vector4(119.70, -894.17, 30.29, 270.53),
            [6] = vector4(0.15, -820.83, 30.69, 275.01),
            [7] = vector4(251.06, -665.72, 38.15, 35.33),
            [8] = vector4(166.84, -586.56, 43.75, 181.04),
            [9] = vector4(337.65, -780.23, 29.29, 60.23),
            [10] = vector4(285.30, -695.81, 29.29, 293.28),
            [11] = vector4(375.44, -735.61, 29.29, 223.31),
            [12] = vector4(376.44, -903.94, 29.29, 275.72),
            [13] = vector4(488.28, -981.97, 27.55, 330.89),
            [14] = vector4(448.99, -1074.80, 29.20, 28.72),
            [15] = vector4(291.72, -1077.72, 29.40, 279.57),
            [16] = vector4(268.42, -1165.24, 29.15, 66.26),
            [17] = vector4(53.58, -1044.62, 29.47, 228.54),
            [18] = vector4(-9.26, -1106.64, 28.94, 198.18),
            [19] = vector4(-42.30, -1085.29, 26.66, 48.13),
            [20] = vector4(2.55, -1024.68, 28.95, 111.37),
            [21] = vector4(-246.04, -1184.39, 23.08, 339.86),
            [22] = vector4(-344.32, -979.43, 29.18, 132.34),
            [23] = vector4(-140.61, -875.97, 29.68, 156.84),
            [24] = vector4(-285.26, -924.05, 31.08, 336.02),
            [25] = vector4(-252.94, -693.16, 33.62, 284.47),
            [26] = vector4(212.97, -320.33, 44.11, 136.94),
            [27] = vector4(74.56, -274.71, 48.13, 170.85),
            [28] = vector4(-38.66, -216.92, 45.79, 139.55),
            [29] = vector4(-256.70, -234.19, 35.82, 102.68)
        }
    },

    Locals = {
        Main = {
            ['MainMenuOpen'] = "Presiona %s para abrir las Misiones de Halloween",
            ['MainRead'] = "Presiona [%s] para Leer",
            ['ClaimReward'] = "Presiona %s para recoger tu premio",
            ['ExitMission'] = "Salir de la Misión",
            ['ExitMissionDes'] = "¿Estás seguro que quieres salir?",
            ['noflashlight'] = "Necesitas una linterna para entrar"
        },
        GhostHunt = {
            ['MenuTitle'] = "Competencia de Caza de Fantasmas",
            ['MenuDesc'] = "Inicia la busqueda definitiva de fantasmas",
            ['InfoHeader'] = "Caza de Fantasmas",
            ['InfoContent'] = "La ciudad esta llena de espiritus inquietos! Usa /tomarfoto cerca de un fantasma para capturarlo. Los fantasmas aparecen de 17:00 a 06:00",
            ['GHMenu1Title'] = "Iniciar Competencia",
            ['GHMenu1Des'] = "Comienza la competencia de fotos de fantasmas",
            ['GHMenu1ContentDes'] = "Ve y toma fotos de fantasmas. Aparecen de 17:00 a 06:00 en la Ciudad y Sandy.",
            ['GHMenu2Head'] = "Participantes de la Competencia",
            ['GHMenu2Title'] = "Ver Participantes",
            ['GHMenu2Des'] = "Ver las entradas de la competencia",
            ['GHMenu3Head'] = "Ganadores de la Competencia",
            ['GHMenu3Title'] = "Ver Ganadores",
            ['GHMenu3Des'] = "Ver los ganadores de la competencia",
            ['GHMenu3NoWinner'] = "Aun no hay participantes! Se el primero en completar la competencia.",
            ['GHMenu4Title'] = "Recoger Premio (mx5halloween)",
            ['GHMenu4Des'] = "Recoge tu vehículo mx5halloween",
            ['NotifyNoClose'] = "No estas lo suficientemente cerca del fantasma!",
            ['NotifyPhoto'] = "Capturaste un fantasma! Sigue buscando el resto.",
            ['NotifyAlreadyFound'] = "Ya encontraste este fantasma!",
            ['NotifyPhotoAll'] = "Felicidades! Capturaste todos los fantasmas.",
            ['NotifyNeedStart'] = "Necesitas iniciar la mision primero en el NPC!",
            ['NotifyCooldown'] = "Debes esperar %s minutos antes de volver a iniciar.",
            ['NotifyCompleted'] = "Ya completaste todos los fantasmas! Espera %s minutos para reiniciar.",
            ['NotifyGhostNotVisible'] = "¡El fantasma no está visible! Solo aparecen de 17:00 a 06:00",
            ['NotifyAlreadyClaimed'] = "Ya recogiste tu premio!",
            ['NotifyClaimSuccess'] = "¡Recogiste tu mx5halloween! Disfruta!",
            ['NotifyNotCompleted'] = "Necesitas completar todos los fantasmas primero!"
        },
        PumpkinHunt = {
            ['MenuTitle'] = "Caza de Calabazas",
            ['MenuDesc'] = "Inicia la caza de calabazas",
            ['InfoHeader'] = "Caza de Calabazas",
            ['InfoContent'] = "Aventurate por la ciudad para encontrar calabazas ocultas. Busca las flechas naranjas!",
            ['InteractOpen'] = "Presiona %s para abrir la calabaza",
            ['InteractPumpkinOpen'] = "Abriendo Calabaza",
            ['NotifyAlreadyOpened'] = "Ya abriste esta calabaza!",
            ['NotifyTrick'] = "Boom! Te asustaron!",
            ['NotifyTreat'] = "Encontraste un premio!",
            ['NeedStart'] = "Necesitas iniciar la mision primero en el NPC!",
            ['NotifyCooldown'] = "Debes esperar %s minutos antes de volver a iniciar.",
            ['NotifyCompleted'] = "Ya recolectaste todas las calabazas! Espera %s minutos para reiniciar.",
            ['NotifyAlreadyClaimed'] = "Ya recogiste tu premio!",
            ['NotifyClaimSuccess'] = "¡Recogiste tu mx5halloween! Disfruta!",
            ['NotifyNotCompleted'] = "Necesitas completar todas las calabazas primero!"
        },
        HauntedHouse = {
            ['MenuTitle'] = "Casa Embrujada",
            ['NotifyReadNote'] = "Lee la nota anterior primero",
            ['NotifyCooldown'] = "Debes esperar %s minutos",
            ['NotifyNoINHouse'] = "No puedes salir de aquí",
            ['ExitMissionDes'] = "¿Quieres salir?",
            ['MissionStart'] = "¿Entrar a la casa?",
            ['Step1a'] = "Nota 1",
            ['Step2a'] = "Nota 2",
            ['Step3a'] = "Nota 3",
            ['Step3b'] = "Continua...",
            ['Step4a'] = "Nota 4",
            ['Step4b'] = "Luz activada",
            ['Step5a'] = "Nota 5",
            ['Step6a'] = "Nota 6",
            ['Step7a'] = "Nota 7",
            ['Step8a'] = "Nota final",
            ['Step8b'] = "Misión completada"
        }
    }
}
