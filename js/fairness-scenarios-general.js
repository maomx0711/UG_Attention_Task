/**
 * 通用生活版 — 公平测试场景库（18组合 × 4变体 = 72轮）
 */
(function (global) {
    'use strict';

    const RATINGS = ['分配公平程度', '程序公平程度', '互动公平程度'];

    const C = {
        victimReject: [
            { key: 'reject', text: '明确反对，要求重新处理', tags: { rejectUnfair: 2, distributive: 2, voiceConcern: 2 } },
            { key: 'negotiate', text: '提出协商，争取更公正的结果', tags: { voiceConcern: 2, distributive: 1 } },
            { key: 'reluctant', text: '不满但暂时接受', tags: { acceptUnfair: 1, distributive: 1 } },
            { key: 'accept', text: '接受现状，避免冲突', tags: { acceptUnfair: 2 } }
        ],
        dominatorFair: [
            { key: 'fair', text: '采取透明、公正的处理方式', tags: { distributive: 2, procedural: 2, interactional: 1 } },
            { key: 'balanced', text: '在规则允许下尽量平衡各方利益', tags: { distributive: 1, procedural: 1 } },
            { key: 'favor', text: '优先考虑与自己关系更近的一方', tags: { acceptUnfair: -2, distributive: -2 } },
            { key: 'self', text: '优先考虑自身利益', tags: { acceptUnfair: -3, distributive: -3 } }
        ],
        bystanderAct: [
            { key: 'intervene', text: '主动介入，为受影响者发声', tags: { intervene: 2, voiceConcern: 2 } },
            { key: 'private', text: '私下支持受影响者，但不公开对抗', tags: { voiceConcern: 1 } },
            { key: 'silent', text: '保持沉默，不介入', tags: { acceptUnfair: 1 } },
            { key: 'support_auth', text: '支持权威方的决定', tags: { acceptUnfair: 2 } }
        ],
        procVictim: [
            { key: 'appeal', text: '申诉并要求公开公正的程序', tags: { rejectUnfair: 2, procedural: 2, voiceConcern: 2 } },
            { key: 'feedback', text: '接受结果但反映程序问题', tags: { procedural: 1, voiceConcern: 1 } },
            { key: 'withdraw', text: '对程序失望，考虑退出', tags: { rejectUnfair: 1, procedural: 1 } },
            { key: 'accept', text: '认为结果比程序更重要', tags: { acceptUnfair: 1, prioritizeOutcome: 2 } }
        ],
        interVictim: [
            { key: 'confront', text: '指出受到的不尊重对待', tags: { voiceConcern: 2, interactional: 2 } },
            { key: 'document', text: '记录经过并向相关部门反映', tags: { voiceConcern: 2, procedural: 1 } },
            { key: 'withdraw', text: '感到受伤但选择回避', tags: { acceptUnfair: 1, interactional: 1 } },
            { key: 'reflect', text: '反思是否自己也有不当之处', tags: { acceptUnfair: 1 } }
        ]
    };

    function tpl(narratives, question, choices) {
        return narratives.map(function (n) {
            return { narrative: n, question: question, choices: choices, ratings: RATINGS };
        });
    }

    const templates = {
        distributive_victim_participant: tpl([
            '你和同伴共同完成社区志愿项目，负责人宣布：同伴获 800 元补贴，你获 200 元，理由是其"贡献更大"，但你认为付出相当。',
            '家庭聚会后，长辈分给表哥一块玉佩，给你一包零食，称"他更懂事"。你全程参与准备。',
            '球队赢得比赛，教练把大部分奖金给了首发，替补球员（包括你）只拿到象征性金额。',
            '合租室友提议按房间大小分摊房租，但公共区域的清洁全由你负责，费用却均摊。'
        ], '面对这种分配，你会怎么做？', C.victimReject),

        distributive_beneficiary_dominator: tpl([
            '你是小区活动组织者，需在两位志愿者间分配 10000 元感谢金，工作量相当，其中一位与你更熟。',
            '家庭财产分配中，你有决定权，需在两位子女间分配遗产，一人照顾父母更多，另一人经济更困难。',
            '你是社团社长，一笔赞助款需分配给两个部门，成员贡献相近，但一个部门与你私交更好。',
            '班级聚餐后剩余 600 元，作为班长你决定如何退还给各组，各组实际垫付金额不完全相同。'
        ], '你会如何分配？', C.dominatorFair),

        distributive_bystander_participant: tpl([
            '你目睹邻居家的孩子因考试成绩获奖励，而另一位同样努力的孩子被忽视，家长当面未表态。',
            '商场促销抽奖，工作人员将大奖给了熟客，你和其他顾客在场目睹全过程。',
            '社区停车位分配中，物业将优质车位给了关系户，排队多年的老人未获分配。',
            '朋友聚会买单时，有人提议按收入分摊，但收入最高者却坚持均摊。'
        ], '作为旁观者，你会如何反应？', C.bystanderAct),

        procedural_victim_participant: tpl([
            '奖学金评选未公开标准，委员会直接公布结果，你未入选，后发现评委与获奖者有关联。',
            '小区业委会改选取消匿名投票，改为举手表决，你感到压力而未投反对票。',
            '比赛裁判临时更改评分规则，你在新规则下得分下降，无缘决赛。',
            '社团换届选举缩短候选人演讲时间，你与另一位候选人被安排在最后且时间被压缩。'
        ], '你认为程序公平吗？你会怎么做？', C.procVictim),

        procedural_beneficiary_dominator: tpl([
            '你是评审组长，时间紧迫：关系好的候选人成绩中等，另一人更优秀但内向，你可简化或完整走流程。',
            '家庭会议决定大额支出，你掌握议程，可选择充分讨论或快速表决。',
            '球队选拔你有最终决定权，可安排公开试训，也可根据印象直接确定名单。',
            '社区公益岗位招聘，你可按规章公开选拔，也可内部推荐熟人。'
        ], '你会如何处理决策程序？', [
            { key: 'full', text: '坚持完整公开流程', tags: { procedural: 2, distributive: 1 } },
            { key: 'simplified', text: '简化流程但公开标准', tags: { procedural: 1 } },
            { key: 'favor', text: '偏向熟人，省略关键环节', tags: { procedural: -2, acceptUnfair: -2 } },
            { key: 'outcome', text: '只看结果，程序从简', tags: { procedural: -1, prioritizeOutcome: 1 } }
        ]),

        procedural_bystander_participant: tpl([
            '课堂上老师随机点名回答，你注意到总是点到同一批学生，其他人很少被提问。',
            '选举中监票员未核对选票就直接唱票，你在场目睹。',
            '比赛抽签环节，组织者当着你的面更换了抽签顺序。',
            '社区投票截止后，有人补交选票并被计入，你参与了全程。'
        ], '你如何看待这个程序？', C.bystanderAct),

        interactional_victim_participant: tpl([
            '会议上你提建议被经理当众打断，随后同事提类似建议却获赞赏。',
            '排队时你被插队，对方对你态度轻蔑，工作人员未制止。',
            '课堂上你回答问题出错被严厉批评，另一位同学犯同样错误只被温和提醒。',
            '亲戚聚会上你的成就被忽视，表兄的类似成就却被大肆表扬。'
        ], '面对这种互动，你会如何反应？', C.interVictim),

        interactional_beneficiary_dominator: tpl([
            '你是餐厅主管，好友小张忘上菜，小李迟到 10 分钟，错误性质类似，你决定如何沟通。',
            '你是班主任，两名学生上课讲话，一人是班干部，你决定如何批评。',
            '你是队长，两名队员训练迟到，一人是主力，你决定如何处罚。',
            '你是房东，两位租客都迟交房租，一位常送礼，你决定如何催缴。'
        ], '你会如何处理？', [
            { key: 'equal', text: '同等态度私下沟通', tags: { interactional: 2, procedural: 1 } },
            { key: 'context', text: '考虑情境但态度一致', tags: { interactional: 1 } },
            { key: 'favor', text: '对关系好者从轻处理', tags: { interactional: -2, acceptUnfair: -2 } },
            { key: 'public', text: '当众区别对待', tags: { interactional: -3, acceptUnfair: -2 } }
        ]),

        interactional_bystander_participant: tpl([
            '课间老师因 A 讲话严厉罚站，五分钟前 B 讲话却只被提醒，你在场。',
            '公交车上售票员对老人态度恶劣，年轻人插话也未被制止，你目睹全程。',
            '邻居因琐事被物业辱骂，另一位邻居犯同样错误却未被追究，你在场。',
            '朋友聚会中有人被当众取笑，另一位说类似话却被当作玩笑，你在场。'
        ], '作为旁观者，你会怎么做？', C.bystanderAct)
    };

    // 补全缺失的 9 个组合（对称扩展）
    templates.distributive_victim_dominator = templates.distributive_beneficiary_dominator;
    templates.distributive_beneficiary_participant = templates.distributive_victim_participant;
    templates.distributive_bystander_dominator = templates.distributive_beneficiary_dominator;
    templates.procedural_victim_dominator = templates.procedural_beneficiary_dominator;
    templates.procedural_beneficiary_participant = templates.procedural_victim_participant;
    templates.procedural_bystander_dominator = templates.procedural_beneficiary_dominator;
    templates.interactional_victim_dominator = templates.interactional_beneficiary_dominator;
    templates.interactional_beneficiary_participant = templates.interactional_victim_participant;
    templates.interactional_bystander_dominator = templates.interactional_beneficiary_dominator;

    const adaptive = {
        followup_reject: {
            id: 'followup_reject',
            dimension: 'distributive', perspective: 'victim', role: 'participant',
            trigger: function (p) { return p.rejectUnfair >= 4; },
            narrative: '【后续】你曾多次维护公平。上司私下表示可帮你争取利益，条件是你不再公开反对。',
            question: '你会如何回应？',
            choices: [
                { key: 'refuse', text: '拒绝交易，坚持正当渠道', tags: { rejectUnfair: 2, procedural: 2 } },
                { key: 'partial', text: '不再公开反对，但要求改善', tags: { voiceConcern: 1 } },
                { key: 'accept', text: '接受交易', tags: { acceptUnfair: 2 } },
                { key: 'report', text: '举报这种交易', tags: { rejectUnfair: 2, intervene: 1 } }
            ],
            ratings: RATINGS
        },
        followup_intervene: {
            id: 'followup_intervene',
            dimension: 'interactional', perspective: 'bystander', role: 'participant',
            trigger: function (p) { return p.intervene >= 4; },
            narrative: '【后续】你曾多次介入不公事件。这次目睹外卖员被顾客辱骂，路人只围观不制止。',
            question: '你会怎么做？',
            choices: [
                { key: 'intervene', text: '上前制止并为外卖员说话', tags: { intervene: 2, interactional: 2 } },
                { key: 'help', text: '报警或联系平台，不直接对峙', tags: { intervene: 1 } },
                { key: 'record', text: '拍摄取证事后维权', tags: { voiceConcern: 1 } },
                { key: 'leave', text: '走开不卷入', tags: { acceptUnfair: 1 } }
            ],
            ratings: RATINGS
        },
        followup_procedure: {
            id: 'followup_procedure',
            dimension: 'procedural', perspective: 'victim', role: 'participant',
            trigger: function (p) { return p.procedural >= 4; },
            narrative: '【后续】你重视程序公正。新政策流程完全合规，但结果对你不利，而关系户受益。',
            question: '你的态度是？',
            choices: [
                { key: 'accept_proc', text: '接受，程序公正即可', tags: { procedural: 2 } },
                { key: 'question', text: '认可程序但质疑标准', tags: { procedural: 1, distributive: 1 } },
                { key: 'reject', text: '要求复核结果', tags: { distributive: 2, rejectUnfair: 1 } },
                { key: 'appeal', text: '申诉并建议改进标准', tags: { voiceConcern: 2 } }
            ],
            ratings: RATINGS
        },
        followup_mixed: {
            id: 'followup_mixed',
            dimension: 'procedural', perspective: 'bystander', role: 'participant',
            trigger: function () { return true; },
            narrative: '【综合】公交车上老人因刷卡机故障被要求下车，售票员不听解释，乘客反应不一。',
            question: '你会怎么做？',
            choices: [
                { key: 'speak', text: '为老人说话要求核实', tags: { intervene: 2, interactional: 1 } },
                { key: 'pay', text: '替老人付车费化解', tags: { voiceConcern: 1, distributive: 1 } },
                { key: 'complain', text: '事后投诉', tags: { voiceConcern: 1, procedural: 1 } },
                { key: 'silent', text: '保持沉默', tags: { acceptUnfair: 1 } }
            ],
            ratings: RATINGS
        }
    };

    global.FAIRNESS_SCENARIO_PACK = {
        id: 'general',
        exportPrefix: 'FairnessGame_General',
        adaptiveInterval: 9,
        templates: templates,
        adaptive: adaptive,
        fallback: {
            id: 'fallback',
            dimension: 'procedural', perspective: 'bystander', role: 'participant',
            narrative: '日常生活中，你遇到一起涉及公平争议的事件，需要做出反应。',
            question: '你通常会怎么做？',
            choices: C.bystanderAct,
            ratings: RATINGS
        }
    };
})(window);
