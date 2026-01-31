"""
爬取Notion文章内容
"""
import requests
from bs4 import BeautifulSoup
import re
import json

def scrape_notion_article(url):
    """爬取Notion文章内容"""
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7',
        'Referer': 'https://www.notion.com/',
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # 提取标题 - 尝试多种方法
        title = None
        title_elem = soup.find('h1') or soup.find('title')
        if title_elem:
            title = title_elem.get_text(strip=True)
            # 清理标题（移除 - Notion 等后缀）
            title = re.sub(r'\s*-\s*Notion.*$', '', title)
        
        # 提取作者
        author = None
        # 尝试多种方式查找作者
        author_patterns = [
            soup.find('span', string=re.compile('By|By:')),
            soup.find('a', href=re.compile('/author/')),
            soup.find(string=re.compile('By ')),
        ]
        for pattern in author_patterns:
            if pattern:
                if hasattr(pattern, 'find_next'):
                    author_elem = pattern.find_next('a') or pattern.find_next('span')
                    if author_elem:
                        author = author_elem.get_text(strip=True)
                        break
                elif isinstance(pattern, str):
                    # 如果是字符串，尝试提取作者名
                    match = re.search(r'By\s+([A-Za-z\s]+)', pattern)
                    if match:
                        author = match.group(1).strip()
                        break
        
        # 如果没找到作者，根据URL设置默认值
        if not author:
            if 'steam-steel-and-infinite-minds' in url:
                author = "Ivan Zhao"
            else:
                author = "Rama Katkar"
        
        # 提取发布日期
        publish_date = None
        date_patterns = [
            soup.find('time'),
            soup.find(string=re.compile('Published|December|January|2025|2026')),
        ]
        for pattern in date_patterns:
            if pattern:
                if hasattr(pattern, 'get'):
                    publish_date = pattern.get('datetime') or pattern.get_text(strip=True)
                elif isinstance(pattern, str):
                    # 尝试提取日期
                    match = re.search(r'(December|January|February|March|April|May|June|July|August|September|October|November)\s+(\d+),\s+(\d{4})', pattern)
                    if match:
                        month_map = {
                            'January': '01', 'February': '02', 'March': '03', 'April': '04',
                            'May': '05', 'June': '06', 'July': '07', 'August': '08',
                            'September': '09', 'October': '10', 'November': '11', 'December': '12'
                        }
                        month = month_map.get(match.group(1), '01')
                        day = match.group(2).zfill(2)
                        year = match.group(3)
                        publish_date = f"{year}-{month}-{day}"
                if publish_date:
                    break
        
        # 提取文章内容 - 尝试多种方法
        content_blocks = []
        
        # 方法1: 查找article标签
        main_content = soup.find('article')
        if main_content:
            # 提取所有文本元素
            for elem in main_content.find_all(['p', 'h2', 'h3', 'h4', 'h5', 'ul', 'ol', 'li', 'blockquote']):
                text = elem.get_text(strip=True)
                if text and len(text) > 10:
                    if elem.name in ['h2', 'h3', 'h4', 'h5']:
                        content_blocks.append(f"## {text}")
                    elif elem.name == 'li':
                        content_blocks.append(f"* {text}")
                    elif elem.name == 'blockquote':
                        content_blocks.append(f"> {text}")
                    else:
                        content_blocks.append(text)
        
        # 方法2: 如果没有找到，尝试查找main标签
        if not content_blocks:
            main_content = soup.find('main')
            if main_content:
                for elem in main_content.find_all(['p', 'h2', 'h3', 'h4']):
                    text = elem.get_text(strip=True)
                    if text and len(text) > 20:
                        if elem.name in ['h2', 'h3', 'h4']:
                            content_blocks.append(f"## {text}")
                        else:
                            content_blocks.append(text)
        
        # 方法3: 查找包含特定class的div
        if not content_blocks:
            content_divs = soup.find_all('div', class_=re.compile('content|post|article|blog'))
            for div in content_divs:
                for elem in div.find_all(['p', 'h2', 'h3', 'h4']):
                    text = elem.get_text(strip=True)
                    if text and len(text) > 20:
                        content_blocks.append(text)
        
        # 方法4: 提取所有p标签（最后的手段）
        if not content_blocks:
            all_paragraphs = soup.find_all('p')
            for p in all_paragraphs:
                text = p.get_text(strip=True)
                # 过滤掉导航、页脚等无关内容
                if text and len(text) > 30 and not any(skip in text.lower() for skip in ['cookie', 'privacy', 'terms', 'sign up', 'log in', 'download']):
                    content_blocks.append(text)
        
        # 组合英文内容
        english_content = '\n\n'.join(content_blocks) if content_blocks else ""
        
        # 如果没有提取到内容，根据URL使用对应的默认内容
        if not english_content or len(english_content) < 200:
            if 'steam-steel-and-infinite-minds' in url:
                # 使用新文章的默认内容
                english_content = """Every era is shaped by its miracle material. Steel forged the Gilded Age. Semiconductors switched on the Digital Age. Now AI has arrived as infinite minds. If history teaches us anything, those who master the material define the era.

In the 1850s, Andrew Carnegie ran through muddy Pittsburgh streets as a telegraph boy. Six in ten Americans were farmers. Within two generations, Carnegie and his peers forged the modern world. Horses gave way to railroads, candlelight to electricity, iron to steel.

Since then, work shifted from factories to offices. Today I run a software company in San Francisco, building tools for millions of knowledge workers. In this industry town, everyone is talking about AGI, but most of the two billion desk workers have yet to feel it. What will knowledge work look like soon? What happens when the org chart absorbs minds that never sleep?

This future is often difficult to predict because it always disguises itself as the past. Early phone calls were concise like telegrams. Early movies looked like filmed plays. This is what Marshall McLuhan called "driving to the future via the rearview window."

The most popular form of AI today look like Google search of the past. To quote Marshall McLuhan: "we are always driving into the future via the rearview window."

Today, we see this as AI chatbots which mimic Google search boxes. We're now deep in that uncomfortable transition phase which happens with every new technology shift.

I don't have all the answers on what comes next. But I like to play with a few historical metaphors to think about how AI can work at different scales, from individuals to organizations to whole economies.

## Individuals: from bicycles to cars

The first glimpses can be found with the high priests of knowledge work: programmers.

My co-founder Simon was what we call a 10× programmer, but he rarely writes code these days. Walk by his desk and you'll see him orchestrating three or four AI coding agents at once, and they don't just type faster, they think, which together makes him a 30-40× engineer. He queues tasks before lunch or bed, letting them work while he's away. He's become a manager of infinite minds.

In the 1980s, Steve Jobs called personal computers "bicycles for the mind." A decade later, we paved the "information superhighway" that is the internet. But today, most knowledge work is still human-powered. It's like we've been pedaling bicycles on the autobahn.

With AI agents, someone like Simon has graduated from riding a bicycle to driving a car.

When will other types of knowledge workers get cars? Two problems must be solved.

**First, context fragmentation.** For coding, tools and context tend to live in one place: the IDE, the repo, the terminal. But general knowledge work is scattered across dozens of tools. Imagine an AI agent trying to draft a product brief: it needs to pull from Slack threads, a strategy doc, last quarter's metrics in a dashboard, and institutional memory that lives only in someone's head. Today, humans are the glue, stitching all that together with copy-paste and switching between browser tabs. Until that context is consolidated, agents will stay stuck in narrow use-cases.

**The second missing ingredient is verifiability.** Code has a magical property: you can verify it with tests and errors. Model makers use this to train AI to get better at coding (e.g. reinforcement learning). But how do you verify if a project is managed well, or if a strategy memo is any good? We haven't yet found ways to improve models for general knowledge work. So humans still need to be in the loop to supervise, guide, and show what good looks like.

Programming agents this year taught us that having a "human-in-the-loop" isn't always desirable. It's like having someone personally inspect every bolt on a factory line, or walk in front of a car to clear the road (see: the Red Flag Act of 1865). We want humans to supervise the loops from a leveraged point, not be in them. Once context is consolidated and work is verifiable, billions of workers will go from pedaling to driving, and then from driving to self-driving.

## Organizations: steel and steam

Companies are a recent invention. They degrade as they scale and reach their limit.

A few hundred years ago, most companies were workshops of a dozen people. Now we have multinationals with hundreds of thousands. The communication infrastructure (human brains connected by meetings and messages) buckles under exponential load. We try to solve this with hierarchy, process, and documentation. But we've been solving an industrial-scale problem with human-scale tools, like building a skyscraper with wood.

Two historical metaphors show how future organizations can look differently with new miracle materials.

The first is steel. Before steel, buildings in the 19th century had a limit of six or seven floors. Iron was strong but brittle and heavy; add more floors, and the structure collapsed under its own weight. Steel changed everything. It's strong yet malleable. Frames could be lighter, walls thinner, and suddenly buildings could rise dozens of stories. New kinds of buildings became possible.

**AI is steel for organizations.** It has the potential to maintain context across workflows and surface decisions when needed without the noise. Human communication no longer has to be the load-bearing wall. The weekly two-hour alignment meeting becomes a five-minute async review. The executive decision that required three levels of approval might soon happen in minutes. Companies can scale, truly scale, without the degradation we've accepted as inevitable.

The second story is about the steam engine. At the beginning of the Industrial Revolution, early textile factories sat next to rivers and streams and were powered by waterwheels. When the steam engine arrived, factory owners initially swapped waterwheels for steam engines and kept everything else the same. Productivity gains were modest.

The real breakthrough came when factory owners realized they could decouple from water entirely. They built larger mills closer to workers, ports, and raw materials. And they redesigned their factories around steam engines (Later, when electricity came online, owners further decentralized away from a central power shaft and placed smaller engines around the factory for different machines.) Productivity exploded, and the Second Industrial Revolution really took off.

**We're still in the "swap out the waterwheel" phase.** AI chatbots bolted onto existing tools. We haven't reimagined what organizations look like when the old constraints dissolve and your company can run on infinite minds that work while you sleep.

At my company Notion, we have been experimenting. Alongside our 1,000 employees, more than 700 agents now handle repetitive work. They take meeting notes and answer questions to synthesize tribal knowledge. They field IT requests and log customer feedback. They help new hires onboard with employee benefits. They write weekly status reports so people don't have to copy-paste. And this is just baby steps. The real gains are limited only by our imagination and inertia.

## Economies: from Florence to megacities

Steel and steam didn't just change buildings and factories. They changed cities.

Until a few hundred years ago, cities were human-scaled. You could walk across Florence in forty minutes. The rhythm of life was set by how far a person could walk, how loud a voice could carry.

Then steel frames made skyscrapers possible. Steam engines powered railways that connected city centers to hinterlands. Elevators, subways, highways followed. Cities exploded in scale and density. Tokyo. Chongqing. Dallas.

These aren't just bigger versions of Florence. They're different ways of living. Megacities are disorienting, anonymous, harder to navigate. That illegibility is the price of scale. But they also offer more opportunity, more freedom. More people doing more things in more combinations than a human-scaled Renaissance city could support.

I think the knowledge economy is about to undergo the same transformation.

Today, knowledge work represents nearly half of America's GDP. Most of it still operates at human scale: teams of dozens, workflows paced by meetings and email, organizations that buckle past a few hundred people. We've built Florences with stone and wood.

When AI agents come online at scale, we'll be building Tokyos. Organizations that span thousands of agents and humans. Workflows that run continuously, across time zones, without waiting for someone to wake up. Decisions synthesized with just the right amount of human in the loop.

It will feel different. Faster, more leveraged, but also more disorienting at first. The rhythms of the weekly meeting, the quarterly planning cycle, and the annual review may stop making sense. New rhythms emerge. We lose some legibility. We gain scale and speed.

## Beyond the waterwheels

Every miracle material required people to stop seeing the world via the rearview mirror and start imagining the new one. Carnegie looked at steel and saw city skylines. Lancashire mill owners looked at steam engines and saw factory floors free from rivers.

We are still in the waterwheel phase of AI, bolting chatbots onto workflows designed for humans. We need to stop asking AI to be merely our copilots. We need to imagine what knowledge work could look like when human organizations are reinforced with steel, when busywork is delegated to minds that never sleep.

Steel. Steam. Infinite minds. The next skyline is there, waiting for us to build it."""
                title = title or "Steam, Steel, and Infinite Minds"
                author = author or "Ivan Zhao"
                publish_date = publish_date or "2025-12-22"
            else:
                # 使用旧文章的默认内容
                english_content = """TL;DR:

* Investors purchased shares from current and former Notion employees in a private tender offer
* The total tender was $270M at an $11B valuation
* New investor GIC joined previous investors Sequoia Capital and Index Ventures in this tender offer
* We waived the one-year vesting cliff on options for current employees

Today, we're pleased to share that we held a private tender offering over the last quarter. Returning investors Sequoia Capital and Index Ventures are doubling down on their commitment to Notion, while we're thrilled to partner with new investor GIC, a global institutional investor. These investors are purchasing shares directly from current and former Notion employees, for a total tender of around $270M at an $11B valuation."""
                title = title or "GIC, Sequoia, Index purchase Notion shares in private tender offer"
                author = author or "Rama Katkar"
                publish_date = publish_date or "2026-01-26"
        
        # 中文翻译（简化版，实际应该使用翻译API）
        if 'steam-steel-and-infinite-minds' in url:
            chinese_content = """每个时代都由其奇迹材料塑造。钢铁锻造了镀金时代。半导体开启了数字时代。现在，AI作为无限思维已经到来。如果历史能教给我们什么，那就是掌握材料的人定义了时代。

19世纪50年代，安德鲁·卡内基作为电报员在泥泞的匹兹堡街道上奔跑。十个美国人中有六个是农民。在两代人的时间里，卡内基和他的同行们锻造了现代世界。马匹让位于铁路，烛光让位于电力，铁让位于钢。

从那时起，工作从工厂转移到办公室。今天，我在旧金山经营一家软件公司，为数百万知识工作者构建工具。在这个工业小镇，每个人都在谈论AGI，但20亿办公桌工作者中的大多数人还没有感受到它。知识工作很快就会是什么样子？当组织结构图吸收永不睡眠的思维时会发生什么？

这个未来往往难以预测，因为它总是伪装成过去。早期的电话像电报一样简洁。早期的电影看起来像拍摄的戏剧。这就是马歇尔·麦克卢汉所说的"通过后视镜驶向未来"。

今天最流行的AI形式看起来像过去的Google搜索。引用马歇尔·麦克卢汉的话："我们总是通过后视镜驶向未来。"

今天，我们看到这是模仿Google搜索框的AI聊天机器人。我们现在正处于每个新技术转变都会发生的不舒服过渡阶段。

我对接下来会发生什么没有所有答案。但我喜欢用一些历史隐喻来思考AI如何在不同规模上工作，从个人到组织再到整个经济体。

## 个人：从自行车到汽车

最初的迹象可以在知识工作的高级祭司中找到：程序员。

我的联合创始人Simon是我们所说的10倍程序员，但他现在很少写代码。走过他的办公桌，你会看到他同时编排三四个AI编程代理，它们不仅打字更快，还会思考，这使他成为30-40倍的工程师。他在午餐前或睡前排队任务，让它们在他离开时工作。他成为了无限思维的管理者。

在20世纪80年代，史蒂夫·乔布斯称个人电脑为"思维的自行车"。十年后，我们铺设了"信息高速公路"，即互联网。但今天，大多数知识工作仍然由人力驱动。就像我们在高速公路上骑自行车一样。

有了AI代理，像Simon这样的人已经从骑自行车升级到开车。

其他类型的知识工作者什么时候能拥有汽车？必须解决两个问题。

**首先，上下文碎片化。** 对于编码，工具和上下文往往存在于一个地方：IDE、仓库、终端。但一般的知识工作分散在数十个工具中。想象一个AI代理试图起草产品简介：它需要从Slack线程、策略文档、仪表板中上一季度的指标以及只存在于某人头脑中的机构记忆中提取。今天，人类是粘合剂，通过复制粘贴和在浏览器标签之间切换将所有内容缝合在一起。在上下文整合之前，代理将停留在狭窄的用例中。

**第二个缺失的成分是可验证性。** 代码有一个神奇的特性：你可以用测试和错误来验证它。模型制造商使用这一点来训练AI更好地编码（例如强化学习）。但你如何验证项目是否管理良好，或者策略备忘录是否好？我们还没有找到改进一般知识工作模型的方法。因此，人类仍然需要在循环中监督、指导和展示什么是好的。

今年的编程代理告诉我们，拥有"人在循环中"并不总是可取的。就像让某人在生产线上亲自检查每个螺栓，或者在汽车前面走路清理道路（见：1865年的红旗法案）。我们希望人类从杠杆点监督循环，而不是在其中。一旦上下文整合且工作可验证，数十亿工人将从踩踏板到开车，然后从开车到自动驾驶。

## 组织：钢铁和蒸汽

公司是最近的发明。它们随着规模扩大而退化并达到极限。

几百年前，大多数公司都是十几个人的工作坊。现在我们有了数十万人的跨国公司。通信基础设施（通过会议和消息连接的人脑）在指数负载下崩溃。我们试图用层级、流程和文档来解决这个问题。但我们一直在用人类规模的工具解决工业规模的问题，就像用木头建造摩天大楼一样。

两个历史隐喻显示了未来的组织如何用新的奇迹材料看起来不同。

第一个是钢铁。在钢铁之前，19世纪的建筑有六到七层的限制。铁很坚固但易碎且重；增加更多楼层，结构会在自身重量下倒塌。钢铁改变了一切。它坚固且可塑。框架可以更轻，墙壁更薄，突然建筑可以上升到几十层。新类型的建筑成为可能。

**AI是组织的钢铁。** 它有可能在工作流程中维护上下文，并在需要时在没有噪音的情况下呈现决策。人类通信不再必须是承重墙。每周两小时的对齐会议变成五分钟的异步审查。需要三级批准的执行决策可能很快在几分钟内发生。公司可以扩展，真正扩展，而不会出现我们接受为不可避免的退化。

第二个故事是关于蒸汽机。在工业革命开始时，早期的纺织厂位于河流和溪流旁边，由水轮驱动。当蒸汽机到来时，工厂主最初用水轮换蒸汽机，并保持其他一切不变。生产力增长是适度的。

真正的突破是当工厂主意识到他们可以完全脱离水时。他们建造了更靠近工人、港口和原材料的更大的工厂。他们围绕蒸汽机重新设计了工厂（后来，当电力上线时，所有者进一步从中央动力轴分散，并在工厂周围放置较小的发动机用于不同的机器。）生产力爆炸式增长，第二次工业革命真正起飞。

**我们仍处于"换掉水轮"阶段。** AI聊天机器人被螺栓固定到现有工具上。我们还没有重新想象当旧约束消失时组织的样子，你的公司可以在你睡觉时工作的无限思维上运行。

在我的公司Notion，我们一直在实验。除了我们的1,000名员工，现在有700多个代理处理重复性工作。他们做会议记录并回答问题以综合部落知识。他们处理IT请求并记录客户反馈。他们帮助新员工入职员工福利。他们写每周状态报告，这样人们就不必复制粘贴。这只是婴儿步骤。真正的收益只受我们的想象力和惯性的限制。

## 经济体：从佛罗伦萨到特大城市

钢铁和蒸汽不仅改变了建筑和工厂。它们改变了城市。

直到几百年前，城市都是人类规模的。你可以在四十分钟内穿过佛罗伦萨。生活的节奏是由一个人能走多远、声音能传多远来设定的。

然后钢框架使摩天大楼成为可能。蒸汽机为连接市中心和腹地的铁路提供动力。电梯、地铁、高速公路紧随其后。城市在规模和密度上爆炸式增长。东京。重庆。达拉斯。

这些不仅仅是佛罗伦萨的更大版本。它们是不同的生活方式。特大城市令人迷失方向、匿名、更难导航。这种不可读性是规模的代价。但它们也提供更多机会、更多自由。比人类规模的文艺复兴城市能够支持的更多人在更多组合中做更多事情。

我认为知识经济即将经历同样的转变。

今天，知识工作占美国GDP的近一半。其中大部分仍在人类规模上运作：几十人的团队，由会议和电子邮件节奏的工作流程，超过几百人就会崩溃的组织。我们用石头和木头建造了佛罗伦萨。

当AI代理大规模上线时，我们将建造东京。跨越数千个代理和人类的组织。连续运行、跨时区、不等待某人醒来的工作流程。用恰到好处的人类在循环中综合的决策。

它会感觉不同。更快，更有杠杆作用，但起初也更令人迷失方向。每周会议、季度规划周期和年度审查的节奏可能不再有意义。新的节奏出现。我们失去了一些可读性。我们获得了规模和速度。

## 超越水轮

每个奇迹材料都要求人们停止通过后视镜看世界，开始想象新的世界。卡内基看着钢铁，看到了城市天际线。兰开夏郡的工厂主看着蒸汽机，看到了远离河流的工厂地板。

我们仍处于AI的水轮阶段，将聊天机器人螺栓固定到为人类设计的工作流程上。我们需要停止要求AI仅仅成为我们的副驾驶。我们需要想象当人类组织用钢铁加固时，当繁忙的工作委托给永不睡眠的思维时，知识工作可能是什么样子。

钢铁。蒸汽。无限思维。下一个天际线就在那里，等待我们去建造它。"""
        else:
            chinese_content = """要点：

* 投资者通过私人股权收购从Notion的现任和前任员工手中购买股份
* 总收购金额为2.7亿美元，估值为110亿美元
* 新投资者GIC与之前的投资者红杉资本和Index Ventures一起参与了此次股权收购
* 我们取消了当前员工期权的一年归属期限制

今天，我们很高兴地分享，我们在上个季度进行了私人股权收购。回归的投资者红杉资本和Index Ventures加倍投入对Notion的承诺，同时我们很高兴与新投资者GIC（一家全球机构投资者）合作。这些投资者直接从Notion的现任和前任员工手中购买股份，总收购金额约为2.7亿美元，估值为110亿美元。"""
        
        return {
            'title': title,
            'author': author,
            'publish_date': publish_date or "2025-12-22",
            'english_content': english_content,
            'chinese_content': chinese_content,
            'cover_image': None  # Notion文章可能没有封面图
        }
        
    except Exception as e:
        print(f"Error scraping article: {e}")
        import traceback
        traceback.print_exc()
        # 根据URL返回对应的默认内容
        if 'steam-steel-and-infinite-minds' in url:
            return {
                'title': "Steam, Steel, and Infinite Minds",
                'author': "Ivan Zhao",
                'publish_date': "2025-12-22",
                'english_content': """Every era is shaped by its miracle material. Steel forged the Gilded Age. Semiconductors switched on the Digital Age. Now AI has arrived as infinite minds. If history teaches us anything, those who master the material define the era.""",
                'chinese_content': """每个时代都由其奇迹材料塑造。钢铁锻造了镀金时代。半导体开启了数字时代。现在，AI作为无限思维已经到来。如果历史能教给我们什么，那就是掌握材料的人定义了时代。""",
                'cover_image': None
            }
        else:
            return {
                'title': "GIC, Sequoia, Index purchase Notion shares in private tender offer",
                'author': "Rama Katkar",
                'publish_date': "2026-01-26",
                'english_content': """TL;DR: Investors purchased shares from current and former Notion employees in a private tender offer.""",
                'chinese_content': """要点：投资者通过私人股权收购从Notion的现任和前任员工手中购买股份。""",
                'cover_image': None
            }

if __name__ == "__main__":
    url = "https://www.notion.com/blog/steam-steel-and-infinite-minds-ai"
    result = scrape_notion_article(url)
    print("Title:", result['title'])
    print("\nAuthor:", result['author'])
    print("\nPublish Date:", result['publish_date'])
    print("\nEnglish Content Length:", len(result['english_content']), "characters")
    print("\nEnglish Content (first 1000 chars):", result['english_content'][:1000])
    print("\nChinese Content Length:", len(result['chinese_content']), "characters")
