import Foundation

/// Static database of 25 evidence-based eye health tips from
/// AAO, WHO, OSHA, and other ophthalmological guidelines.
///
/// Tips cover: tear film, screen distance, lighting, humidity,
/// posture, outdoor time, nutrition, blue light, and more.
enum TipDatabase {

    /// All available eye health tips, ordered by ID.
    static let tips: [EyeHealthTip] = [
        EyeHealthTip(
            id: 1,
            title: "Blink 20 times to refresh your tear film",
            titleChinese: "眨眼20次刷新泪膜",
            description: "Staring at screens reduces blink rate by up to 60%. Consciously blinking 20 times restores the tear film and reduces dry eye symptoms.",
            descriptionChinese: "盯着屏幕会使眨眼频率降低60%。有意识地眨眼20次可以恢复泪膜，减少干眼症状。",
            source: "AAO (American Academy of Ophthalmology)",
            icon: "eye"
        ),
        EyeHealthTip(
            id: 2,
            title: "Keep screen 20-26 inches from eyes",
            titleChinese: "屏幕距离保持50-65厘米",
            description: "Position your screen at arm's length (20-26 inches / 50-65 cm). Closer distances increase eye strain and convergence demand.",
            descriptionChinese: "将屏幕放在一臂距离（50-65厘米）处。距离过近会增加眼睛疲劳和调节负担。",
            source: "AAO",
            icon: "ruler"
        ),
        EyeHealthTip(
            id: 3,
            title: "Adjust lighting to reduce glare",
            titleChinese: "调节光线减少眩光",
            description: "Ambient lighting should be about half as bright as a typical office. Use curtains or blinds to minimize glare on the screen.",
            descriptionChinese: "环境光线应约为一般办公室的一半亮度。使用窗帘或百叶窗减少屏幕眩光。",
            source: "OSHA (Occupational Safety and Health Administration)",
            icon: "lightbulb"
        ),
        EyeHealthTip(
            id: 4,
            title: "Maintain room humidity 30-65%",
            titleChinese: "保持室内湿度30-65%",
            description: "Low humidity accelerates tear evaporation. Use a humidifier in dry environments to maintain 30-65% relative humidity.",
            descriptionChinese: "低湿度会加速泪液蒸发。在干燥环境中使用加湿器保持30-65%的相对湿度。",
            source: "AAO",
            icon: "humidity"
        ),
        EyeHealthTip(
            id: 5,
            title: "Position screen slightly below eye level",
            titleChinese: "屏幕略低于视线水平",
            description: "The top of your screen should be at or slightly below eye level. Looking slightly downward reduces the exposed ocular surface and dry eye.",
            descriptionChinese: "屏幕顶部应与视线平齐或略低。略微向下看可以减少眼表暴露面积，减少干眼。",
            source: "AAO",
            icon: "arrow.down.to.line"
        ),
        EyeHealthTip(
            id: 6,
            title: "Use Night Shift after sunset",
            titleChinese: "日落后使用Night Shift",
            description: "Blue light from screens can disrupt circadian rhythm. Enable Night Shift or warm color temperature after sunset.",
            descriptionChinese: "屏幕蓝光会干扰生物钟。日落后开启Night Shift或暖色温模式。",
            source: "AAO",
            icon: "moon.fill"
        ),
        EyeHealthTip(
            id: 7,
            title: "Get 20+ minutes outdoor light daily",
            titleChinese: "每天户外活动20分钟+",
            description: "Outdoor light exposure reduces myopia progression in children and adults. Aim for at least 20 minutes of natural light daily.",
            descriptionChinese: "户外光线暴露可以减缓儿童和成人的近视进展。每天至少20分钟自然光照。",
            source: "WHO (World Health Organization)",
            icon: "sun.max"
        ),
        EyeHealthTip(
            id: 8,
            title: "Follow the 20-20-20 rule",
            titleChinese: "遵循20-20-20法则",
            description: "Every 20 minutes, look at something 20 feet (6 meters) away for at least 20 seconds. This relaxes the ciliary muscles.",
            descriptionChinese: "每20分钟，看6米远的物体至少20秒。这可以放松睫状肌。",
            source: "AAO",
            icon: "eyes"
        ),
        EyeHealthTip(
            id: 9,
            title: "Stay hydrated to prevent dry eyes",
            titleChinese: "多喝水预防干眼",
            description: "Dehydration reduces tear production. Drink 6-8 glasses of water daily to maintain healthy tear film.",
            descriptionChinese: "脱水会减少泪液分泌。每天喝6-8杯水以保持健康的泪膜。",
            source: "AAO",
            icon: "drop.fill"
        ),
        EyeHealthTip(
            id: 10,
            title: "Eat omega-3 rich foods for eye health",
            titleChinese: "摄取富含Omega-3的食物",
            description: "Omega-3 fatty acids (found in fish, flaxseed, walnuts) support tear film stability and reduce dry eye inflammation.",
            descriptionChinese: "Omega-3脂肪酸（鱼类、亚麻籽、核桃）有助于稳定泪膜，减少干眼炎症。",
            source: "AAO",
            icon: "leaf.fill"
        ),
        EyeHealthTip(
            id: 11,
            title: "Clean your screen regularly",
            titleChinese: "定期清洁屏幕",
            description: "Dust and fingerprints on screens reduce contrast and increase glare, forcing your eyes to work harder.",
            descriptionChinese: "屏幕上的灰尘和指纹会降低对比度、增加眩光，让眼睛更加吃力。",
            source: "OSHA",
            icon: "sparkles"
        ),
        EyeHealthTip(
            id: 12,
            title: "Use artificial tears if eyes feel dry",
            titleChinese: "眼睛干涩时使用人工泪液",
            description: "Preservative-free artificial tears can supplement your natural tear film. Use as needed, especially in air-conditioned rooms.",
            descriptionChinese: "不含防腐剂的人工泪液可以补充天然泪膜。在空调房间中特别需要。",
            source: "AAO",
            icon: "drop.triangle"
        ),
        EyeHealthTip(
            id: 13,
            title: "Wear UV-protective sunglasses outdoors",
            titleChinese: "户外戴防紫外线太阳镜",
            description: "UV radiation damages the cornea, lens, and retina. Choose sunglasses that block 99-100% of UV-A and UV-B rays.",
            descriptionChinese: "紫外线会损害角膜、晶状体和视网膜。选择能阻挡99-100% UV-A和UV-B射线的太阳镜。",
            source: "WHO",
            icon: "sunglasses"
        ),
        EyeHealthTip(
            id: 14,
            title: "Increase font size if squinting",
            titleChinese: "看不清就放大字体",
            description: "If you lean forward or squint to read, increase font size or zoom level. This reduces accommodation strain.",
            descriptionChinese: "如果需要前倾或眯眼看屏幕，请放大字体。这可以减少调节负担。",
            source: "OSHA",
            icon: "textformat.size.larger"
        ),
        EyeHealthTip(
            id: 15,
            title: "Get annual comprehensive eye exams",
            titleChinese: "每年进行全面眼科检查",
            description: "Many eye conditions (glaucoma, macular degeneration) have no early symptoms. Annual exams catch problems early.",
            descriptionChinese: "许多眼部疾病（青光眼、黄斑变性）早期无症状。年度检查可以及早发现问题。",
            source: "AAO",
            icon: "cross.case"
        ),
        EyeHealthTip(
            id: 16,
            title: "Avoid rubbing your eyes",
            titleChinese: "避免揉眼睛",
            description: "Rubbing eyes can transfer bacteria, worsen allergies, and increase intraocular pressure. Use cold compress instead.",
            descriptionChinese: "揉眼睛会传播细菌、加重过敏、增加眼压。改用冷敷代替。",
            source: "AAO",
            icon: "hand.raised.slash"
        ),
        EyeHealthTip(
            id: 17,
            title: "Take a 5-minute break every hour",
            titleChinese: "每小时休息5分钟",
            description: "Prolonged screen use causes digital eye strain. Stand, stretch, and look away for 5 minutes every hour.",
            descriptionChinese: "长时间使用屏幕会导致数字眼疲劳。每小时站起来伸展活动5分钟。",
            source: "OSHA",
            icon: "clock"
        ),
        EyeHealthTip(
            id: 18,
            title: "Eat leafy greens for lutein and zeaxanthin",
            titleChinese: "多吃绿叶蔬菜补充叶黄素",
            description: "Spinach, kale, and collard greens contain lutein and zeaxanthin — antioxidants that protect the macula from blue light damage.",
            descriptionChinese: "菠菜、甘蓝等绿叶蔬菜含有叶黄素和玉米黄质——保护黄斑免受蓝光损伤的抗氧化剂。",
            source: "AAO",
            icon: "carrot"
        ),
        EyeHealthTip(
            id: 19,
            title: "Adjust screen brightness to match surroundings",
            titleChinese: "屏幕亮度与环境相匹配",
            description: "Your screen should be neither significantly brighter nor dimmer than your surroundings. Auto-brightness helps maintain balance.",
            descriptionChinese: "屏幕亮度不应明显高于或低于周围环境。自动亮度有助于保持平衡。",
            source: "OSHA",
            icon: "sun.min"
        ),
        EyeHealthTip(
            id: 20,
            title: "Avoid using screens in total darkness",
            titleChinese: "避免在全黑环境中使用屏幕",
            description: "Extreme contrast between screen and dark surroundings causes pupil fatigue. Keep a dim ambient light on.",
            descriptionChinese: "屏幕与黑暗环境的极端对比会导致瞳孔疲劳。保持一盏昏暗的环境灯。",
            source: "AAO",
            icon: "lightbulb.slash"
        ),
        EyeHealthTip(
            id: 21,
            title: "Palming relaxes tired eyes in 30 seconds",
            titleChinese: "掌心热敷30秒放松疲劳眼睛",
            description: "Rub palms together until warm, then cup over closed eyes for 30 seconds. The warmth and darkness relax the ciliary muscles.",
            descriptionChinese: "双手搓热，然后轻轻覆盖闭合的双眼30秒。温暖和黑暗可以放松睫状肌。",
            source: "AAO",
            icon: "hand.raised.fill"
        ),
        EyeHealthTip(
            id: 22,
            title: "Position air vents away from your face",
            titleChinese: "空调出风口避开面部",
            description: "Direct airflow from fans, AC, or heaters accelerates tear evaporation. Position vents so they don't blow directly at your eyes.",
            descriptionChinese: "风扇、空调或暖气的直吹会加速泪液蒸发。调整出风口方向避免直吹眼睛。",
            source: "AAO",
            icon: "wind"
        ),
        EyeHealthTip(
            id: 23,
            title: "Use an anti-glare screen filter",
            titleChinese: "使用防眩光屏幕保护膜",
            description: "Matte anti-glare filters reduce reflections from windows and overhead lighting, decreasing eye strain.",
            descriptionChinese: "哑光防眩光保护膜可以减少窗户和顶灯的反射，降低眼睛疲劳。",
            source: "OSHA",
            icon: "rectangle.inset.filled"
        ),
        EyeHealthTip(
            id: 24,
            title: "Children need 2+ hours outdoor daily",
            titleChinese: "儿童每天户外活动2小时+",
            description: "Studies show 2+ hours of outdoor time significantly reduces myopia onset and progression in children aged 6-14.",
            descriptionChinese: "研究表明每天2小时以上户外活动可以显著降低6-14岁儿童近视的发生和进展。",
            source: "WHO",
            icon: "figure.play"
        ),
        EyeHealthTip(
            id: 25,
            title: "Stretch neck and shoulders regularly",
            titleChinese: "定期伸展颈部和肩部",
            description: "Tension in the neck and shoulders restricts blood flow to the eyes. Stretch regularly to maintain circulation.",
            descriptionChinese: "颈部和肩部的紧张会限制眼部血液循环。定期伸展以保持良好的血液循环。",
            source: "OSHA",
            icon: "figure.cooldown"
        ),
    ]

    /// Returns a random tip from the database.
    static func randomTip() -> EyeHealthTip {
        tips.randomElement() ?? tips[0]
    }

    /// Returns a tip for "Tip of the Day" based on the date.
    /// Uses the day-of-year as a deterministic index.
    static func tipOfTheDay(for date: Date = .now) -> EyeHealthTip {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % tips.count
        return tips[index]
    }

    /// Returns the next tip in sequence after the given tip ID.
    static func nextTip(after currentId: Int) -> EyeHealthTip {
        guard let currentIndex = tips.firstIndex(where: { $0.id == currentId }) else {
            return tips[0]
        }
        let nextIndex = (currentIndex + 1) % tips.count
        return tips[nextIndex]
    }
}
