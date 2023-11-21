library(tidyverse)

sensor_data <- read_csv("data/oregon/oregon_sensor.csv") %>% 
  rename(CSE_PlayerID = CSE_PlayerID...3)

offensive_metrics <- sensor_data %>% 
  select(CSE_PlayerID, FirstName, LastName,
         Obj_ExitVelo_Swing1, Obj_ExitVelo_Swing2, Obj_ExitVelo_Swing3,
         Plane, Connection, Rotation, BatSpeed, RotationalAcceleration,
         Power, TimeToContact, PeakHandSpeed, OnPlaneEfficiency, AttackAngle, 
         starts_with("Obj_FootSpeed")) %>% 
  mutate(LastName = ifelse(LastName == "Desario", "DeSario", LastName),
         FirstName = ifelse(FirstName == "Isabella", "Bella", FirstName),
         name = paste(FirstName, LastName))

defensive_metrics <- sensor_data %>% 
  select(CSE_PlayerID, FirstName, LastName,
         starts_with("Obj_ArmVelo"), starts_with("Obj_PopTime"))

hitting_box <- read_csv("data/oregon/oregon_hitting_box.csv") %>% 
  rename(player_id = player_id...4)

woba_values <- read_csv("2023_run_values_woba.csv") %>% 
  column_to_rownames("...1")

positions <- hitting_box %>% 
  separate(pos, c("pos1", "pos2"), sep = "/") %>% 
  pivot_longer(cols = starts_with("pos")) %>% 
  drop_na(value) %>% 
  filter(value %in% c("C", "1B", "2B", "SS", "3B", "LF", "CF", "RF", "P")) %>% 
  group_by(player_id, value) %>% 
  summarise(games = n()) %>% 
  slice_max(n = 1, order_by = games, with_ties = FALSE) %>% 
  rename(pos = value)

hitting_stats <- hitting_box %>% 
  group_by(player_id, team_id, first_name, last_name) %>% 
  filter(season == 2023) %>% 
  summarise(uBB = sum(bb_2),
            HBP = sum(hbp),
            H = sum(h),
            x1B = sum(h) - sum(x2b) - sum(x3b) - sum(hr),
            x2B = sum(x2b),
            x3B = sum(x3b),
            HR = sum(hr),
            AB = sum(ab),
            SF = sum(sf),
            PA = AB + uBB + SF + HBP,
            AVG = H / AB,
            OBP = (x1B + x2B  + x3B + HR + uBB + HBP) / PA,
            SLG = sum(tb) / AB,
            OPS = OBP + SLG) %>% 
  ungroup() %>% 
  mutate(wOBA = ((woba_values["uBB", "woba_weights"]*uBB) + (woba_values["HBP", "woba_weights"]*HBP) + 
                   (woba_values["1B", "woba_weights"]*x1B) + (woba_values["2B", "woba_weights"]*x2B) + 
                   (woba_values["3B", "woba_weights"]*x3B) + (woba_values["HR", "woba_weights"]*HR)) / (AB + uBB + SF + HBP),
         league_wOBA = mean(wOBA, na.rm = T),
         league_OBP = mean(OBP, na.rm = T),
         wOBA_scale = league_wOBA / league_OBP,
         wRAA = round(((wOBA - league_wOBA) / wOBA_scale) * PA, 4),
         wRAA_per_100_PA = (wRAA / PA) * 100) %>% 
  merge(positions, by = "player_id") %>% 
  select(player_id, first_name, last_name, pos, PA, AVG, OPS, H, x2B, x3B, HR, wRAA, wRAA_per_100_PA) %>% 
  mutate(first_name = case_when(first_name == "KK" ~ 'Kaitlynn "KK"',
                                TRUE ~ first_name))

offensive_data <- merge(offensive_metrics, hitting_stats, 
                        by.x = c("FirstName", "LastName"),
                        by.y = c("first_name", "last_name"), all = T) %>% 
  rowwise() %>% 
  mutate(pos = case_when(name == "Abby Mulvey" ~ "C",
                         TRUE ~ pos),
         PositionID = case_when(pos == "C" ~ 1,
                                pos %in% c("1B", "3B") ~ 2,
                                pos %in% c("2B", "SS") ~ 3,
                                pos %in% c("RF", "CF", "LF", "OF") ~ 4,
                                pos == "P" ~ 5,
                                TRUE ~ NA),
         exitVelo = median(c(Obj_ExitVelo_Swing1, Obj_ExitVelo_Swing2, Obj_ExitVelo_Swing3), na.rm = T),
         H1 = median(c(Obj_FootSpeed_H11, Obj_FootSpeed_H12), na.rm = T),
         HH = median(c(Obj_FootSpeed_HH1, Obj_FootSpeed_HH2), na.rm = T),
         agility = median(c(Obj_FootSpeed_5_10_5_Trial1, Obj_FootSpeed_5_10_5_Trial2), na.rm = T),
         across(.cols = c(AVG, OPS),
                .fns = \(col) format(round(col, 3), digits = 3)),
         across(.cols = c(wRAA, wRAA_per_100_PA),
                .fns = \(col) format(round(col, 2), digits = 2))) %>% 
  arrange(desc(PA))

write.csv(offensive_data, "~/CSE/ResearchAndDevelopment/data/oregon/offensive_data.csv")
