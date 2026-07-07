/**
 * 职场工作版 — 公平测试场景库（18组合 × 4变体 = 72轮）
 */
(function (global) {
    'use strict';

    const RATINGS = ['分配公平程度', '程序公平程度', '互动公平程度'];

    const C = {
        victimReject: [
            { key: 'reject', text: '向 HR 或上级正式申诉，要求重新评估', tags: { rejectUnfair: 2, distributive: 2, voiceConcern: 2 } },
            { key: 'negotiate', text: '与主管一对一沟通，提出重新分配', tags: { voiceConcern: 2, distributive: 1 } },
            { key: 'reluctant', text: '不满但接受，避免影响考核', tags: { acceptUnfair: 1 } },
            { key: 'accept', text: '接受安排，专注本职工作', tags: { acceptUnfair: 2 } }
        ],
        dominatorFair: [
            { key: 'fair', text: '按公开标准公正分配', tags: { distributive: 2, procedural: 2 } },
            { key: 'balanced', text: '综合考量但保持透明', tags: { distributive: 1, procedural: 1 } },
            { key: 'favor', text: '倾向核心下属或关系更近者', tags: { acceptUnfair: -2, distributive: -2 } },
            { key: 'self', text: '优先保障自己部门/个人利益', tags: { acceptUnfair: -3 } }
        ],
        bystanderAct: [
            { key: 'intervene', text: '在会议或邮件中提出质疑', tags: { intervene: 2, voiceConcern: 2 } },
            { key: 'private', text: '私下支持受影响同事', tags: { voiceConcern: 1 } },
            { key: 'silent', text: '不介入，避免站队', tags: { acceptUnfair: 1 } },
            { key: 'support_mgmt', text: '支持管理层决定', tags: { acceptUnfair: 2 } }
        ],
        procVictim: [
            { key: 'appeal', text: '要求公开评选标准并申诉', tags: { rejectUnfair: 2, procedural: 2, voiceConcern: 2 } },
            { key: 'hr', text: '向 HR 反映程序问题', tags: { procedural: 1, voiceConcern: 1 } },
            { key: 'transfer', text: '考虑转岗或离职', tags: { rejectUnfair: 1 } },
            { key: 'accept', text: '接受结果，结果比过程重要', tags: { acceptUnfair: 1, prioritizeOutcome: 2 } }
        ],
        interVictim: [
            { key: 'confront', text: '与主管沟通指出不尊重对待', tags: { voiceConcern: 2, interactional: 2 } },
            { key: 'hr_report', text: '向 HR 记录并反映', tags: { voiceConcern: 2, procedural: 1 } },
            { key: 'avoid', text: '减少与该上级互动', tags: { acceptUnfair: 1 } },
            { key: 'adjust', text: '调整自身沟通方式', tags: { acceptUnfair: 1 } }
        ]
    };

    function tpl(narratives, question, choices) {
        return narratives.map(function (n) {
            return { narrative: n, question: question, choices: choices, ratings: RATINGS };
        });
    }

    const templates = {
        distributive_victim_participant: tpl([
            '你与同事共同完成季度项目，经理宣布奖金分配：对方 5 万，你 1 万，理由是其"牵头"，但你认为贡献相当。',
            '部门年终奖按职级发放，你与同职级同事工作量相当，但对方因"潜力"获更高系数。',
            '销售提成结算中，你开发的客户被划给另一位同事，提成也随客户转移。',
            '加班补贴申报中，你与同事加班时长相近，但你的申请被驳回，对方的却通过。'
        ], '面对这种职场分配，你会怎么做？', C.victimReject),

        distributive_beneficiary_dominator: tpl([
            '你是部门经理，需在两名下属间分配 8 万元项目奖金，工作量相当，一位是你的心腹。',
            '你是项目负责人，需在组内分配署名顺序和奖金比例，有人私下找你"打招呼"。',
            '裁员补偿预算有限，你需决定留用名额与补偿金额，两名员工绩效相近。',
            '团建经费 2 万元，你决定如何在各小组间分配，其中一组与你关系更密切。'
        ], '作为支配者，你会如何分配？', C.dominatorFair),

        distributive_bystander_participant: tpl([
            '部门会议上，经理将优质客户资源全部分给某同事，其他同事未获解释，你在场目睹。',
            '你听说 HR 将晋升名额内定给领导的亲戚，同期入职的同事议论纷纷。',
            '跨部门协作中，功劳被某团队独占，实际参与的你的部门同事未获认可，你知情。',
            '年终奖发放后，同岗同事发现分配差异巨大，有人当面质疑，经理未回应。'
        ], '作为职场旁观者，你会如何反应？', C.bystanderAct),

        procedural_victim_participant: tpl([
            '年度评优未公布标准，结果宣布你未入选，后发现评委与获奖者关系密切。',
            '晋升答辩中你的陈述时间被压缩，另一位候选人获额外提问机会。',
            '绩效考核指标在年末临时调整，你在新指标下评级下降。',
            '部门竞聘采用"内部推荐"，你未获推荐机会，岗位给了领导赏识的人。'
        ], '你认为这个职场程序公平吗？', C.procVictim),

        procedural_beneficiary_dominator: tpl([
            '你是晋升委员会成员，可决定走完整答辩流程，或直接推荐关系好的候选人。',
            '你是 HRBP，裁员名单可由你按规章评估，也可按领导意向"优化"。',
            '招聘终面你有否决权，可坚持结构化面试，也可"感觉不对"直接否掉。',
            '项目评优你掌握流程设计权，可公开投票，也可私下征求领导意见后定案。'
        ], '你会如何设计/执行决策程序？', [
            { key: 'full', text: '坚持完整、透明、可申诉的流程', tags: { procedural: 2 } },
            { key: 'simplified', text: '简化流程但公开标准', tags: { procedural: 1 } },
            { key: 'favor', text: '走形式，实质内定', tags: { procedural: -2, acceptUnfair: -2 } },
            { key: 'outcome', text: '结果导向，程序从简', tags: { prioritizeOutcome: 1 } }
        ]),

        procedural_bystander_participant: tpl([
            '全公司大会上，领导临时修改评优规则，你观察到部分同事面露不满。',
            '招聘面试中，面试官对某校毕业生明显更宽松，你在旁协助记录。',
            '部门周会上，决议在未充分讨论下被领导快速通过，你参与了会议。',
            '360 评估中，有人被恶意低分，你知晓评分者与被评者有过节。'
        ], '你如何看待这个程序？', C.bystanderAct),

        interactional_victim_participant: tpl([
            '周会上你提方案被总监当众否定，随后另一位同事提类似方案却获认可。',
            '邮件中你请示工作，主管回复冷淡；对另一位同事类似请示则耐心指导。',
            '团建活动中你的贡献未被提及，同事的类似贡献被领导点名表扬。',
            '绩效面谈中，主管对你使用指责语气，对另一位犯类似错误的同事则温和。'
        ], '面对这种职场互动，你会如何反应？', C.interVictim),

        interactional_beneficiary_dominator: tpl([
            '你是主管，两名下属犯类似错误：心腹迟到，另一人报告格式有误，你决定如何批评。',
            '你是项目经理，组员汇报时你频繁打断某人，对另一人则耐心听完。',
            '你是 HR，处理投诉时对熟人轻描淡写，对陌生人则从严处理。',
            '你是部门负责人，在全员会上表扬谁、批评谁，你有完全自主权。'
        ], '你会如何处理与下属/同事的互动？', [
            { key: 'equal', text: '一视同仁，私下平等沟通', tags: { interactional: 2, procedural: 1 } },
            { key: 'context', text: '因人因事但态度一致', tags: { interactional: 1 } },
            { key: 'favor', text: '对亲信更宽容', tags: { interactional: -2, acceptUnfair: -2 } },
            { key: 'public', text: '当众区别对待以立威', tags: { interactional: -3 } }
        ]),

        interactional_bystander_participant: tpl([
            '会议上新人被领导当众嘲讽，资深同事犯类似错误却无人提及，你在场。',
            '茶水间听到主管对某员工有人身攻击式批评，你对该员工印象良好。',
            '跨部门协作中，对方负责人对你的同事态度傲慢，对你却客气，你目睹。',
            '公司群里有人被公开点名批评，你知道责任实际在另一部门。'
        ], '作为旁观者，你会怎么做？', C.bystanderAct)
    };

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
        followup_promotion: {
            id: 'wp_followup_promotion',
            dimension: 'procedural', perspective: 'victim', role: 'participant',
            trigger: function (p) { return p.procedural >= 4 || p.rejectUnfair >= 4; },
            narrative: '【后续】你曾多次质疑不公。这次晋升答辩流程规范，但评委主任是竞争对手的导师，你未获晋升。',
            question: '你会怎么做？',
            choices: [
                { key: 'accept', text: '接受，程序合规', tags: { procedural: 2 } },
                { key: 'appeal', text: '申诉利益冲突问题', tags: { rejectUnfair: 2, voiceConcern: 2 } },
                { key: 'leave', text: '考虑跳槽', tags: { rejectUnfair: 1 } },
                { key: 'silent', text: '沉默，继续工作', tags: { acceptUnfair: 1 } }
            ],
            ratings: RATINGS
        },
        followup_credit: {
            id: 'wp_followup_credit',
            dimension: 'distributive', perspective: 'victim', role: 'participant',
            trigger: function (p) { return p.distributive >= 4; },
            narrative: '【后续】你重视分配公平。领导让你"配合"将项目功劳让给更有背景的同事，承诺下次补偿你。',
            question: '你会如何回应？',
            choices: [
                { key: 'refuse', text: '拒绝，要求如实记录贡献', tags: { rejectUnfair: 2, voiceConcern: 2 } },
                { key: 'deal', text: '这次配合，换取下次机会', tags: { acceptUnfair: 1 } },
                { key: 'document', text: '留证并向 HR 备案', tags: { voiceConcern: 2, procedural: 1 } },
                { key: 'accept', text: '接受，避免得罪领导', tags: { acceptUnfair: 2 } }
            ],
            ratings: RATINGS
        },
        followup_whistleblow: {
            id: 'wp_followup_whistleblow',
            dimension: 'interactional', perspective: 'bystander', role: 'participant',
            trigger: function (p) { return p.intervene >= 4; },
            narrative: '【后续】你曾多次为同事发声。这次发现部门存在系统性加班不补偿，多人敢怒不敢言。',
            question: '你会怎么做？',
            choices: [
                { key: 'collective', text: '联合同事向劳动监察或 HR 反映', tags: { intervene: 2, voiceConcern: 2 } },
                { key: 'individual', text: '个人匿名举报', tags: { voiceConcern: 1 } },
                { key: 'negotiate', text: '与主管私下协商', tags: { voiceConcern: 1 } },
                { key: 'silent', text: '不介入，保护自己', tags: { acceptUnfair: 1 } }
            ],
            ratings: RATINGS
        },
        followup_mixed: {
            id: 'wp_followup_mixed',
            dimension: 'procedural', perspective: 'bystander', role: 'participant',
            trigger: function () { return true; },
            narrative: '【综合】公司宣布"优化"裁员，名单未经过公示程序，你同事在列，他司龄长且绩效中等。',
            question: '你会怎么做？',
            choices: [
                { key: 'support', text: '协助同事争取合法补偿和透明流程', tags: { intervene: 2, procedural: 2 } },
                { key: 'private', text: '私下安慰并提供求职帮助', tags: { voiceConcern: 1 } },
                { key: 'relief', text: '庆幸不是自己，保持沉默', tags: { acceptUnfair: 1 } },
                { key: 'justify', text: '认为公司有权决定', tags: { acceptUnfair: 2 } }
            ],
            ratings: RATINGS
        }
    };

    global.FAIRNESS_SCENARIO_PACK = {
        id: 'workplace',
        exportPrefix: 'FairnessGame_Workplace',
        adaptiveInterval: 9,
        templates: templates,
        adaptive: adaptive,
        fallback: {
            id: 'wp_fallback',
            dimension: 'procedural', perspective: 'bystander', role: 'participant',
            narrative: '职场中你遇到一起涉及公平争议的事件，需要做出反应。',
            question: '你通常会怎么做？',
            choices: C.bystanderAct,
            ratings: RATINGS
        }
    };
})(window);
