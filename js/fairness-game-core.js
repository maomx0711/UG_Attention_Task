/**
 * 公平观念互动测试 — 共享引擎
 * 支持 72 轮对话、自适应分支、三维公平地图确认
 */
(function (global) {
    'use strict';

    const DIMENSION_LABELS = {
        distributive: '分配公平',
        procedural: '程序公平',
        interactional: '互动公平'
    };

    const PERSPECTIVE_LABELS = {
        victim: '受害者视角',
        beneficiary: '获利者视角',
        bystander: '旁观者视角'
    };

    const ROLE_LABELS = {
        participant: '参与者',
        dominator: '支配者'
    };

    const DIMENSIONS = ['distributive', 'procedural', 'interactional'];
    const PERSPECTIVES = ['victim', 'beneficiary', 'bystander'];
    const ROLES = ['participant', 'dominator'];

    function shuffleArray(arr) {
        const a = arr.slice();
        for (let i = a.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [a[i], a[j]] = [a[j], a[i]];
        }
        return a;
    }

    function templateKey(dimension, perspective, role) {
        return dimension + '_' + perspective + '_' + role;
    }

    function allComboKeys() {
        const keys = [];
        for (const d of DIMENSIONS) {
            for (const p of PERSPECTIVES) {
                for (const r of ROLES) {
                    keys.push(templateKey(d, p, r));
                }
            }
        }
        return keys;
    }

    function createGameState(config) {
        return {
            subjectID: '',
            scenarioPtr: 0,
            scenarioCache: {},
            responses: [],
            mapPosition: null,
            mapConfirmed: false,
            profile: {
                distributive: 0,
                procedural: 0,
                interactional: 0,
                acceptUnfair: 0,
                rejectUnfair: 0,
                intervene: 0,
                voiceConcern: 0,
                prioritizeProcedure: 0,
                prioritizeOutcome: 0,
                prioritizeInteraction: 0
            },
            config: config
        };
    }

    function updateProfile(gameState, tags) {
        if (!tags) return;
        for (const [key, value] of Object.entries(tags)) {
            if (gameState.profile[key] !== undefined) {
                gameState.profile[key] += value;
            }
        }
    }

    function instantiateScenario(raw, index, pack) {
        const id = raw.id || ('round_' + (index + 1));
        return {
            id: id,
            dimension: raw.dimension,
            perspective: raw.perspective,
            role: raw.role,
            narrative: raw.narrative,
            question: raw.question,
            choices: raw.choices,
            ratings: raw.ratings || ['分配公平程度', '程序公平程度', '互动公平程度'],
            isAdaptive: !!raw.isAdaptive
        };
    }

    function generateTemplateScenario(gameState, index, pack) {
        const combos = allComboKeys();
        const combo = combos[index % combos.length];
        const variantIdx = Math.floor(index / combos.length);
        const parts = combo.split('_');
        const role = parts.pop();
        const perspective = parts.pop();
        const dimension = parts.join('_');

        const templates = pack.templates[combo] || pack.templates[templateKey(dimension, perspective, role)];
        if (!templates || !templates.length) {
            return instantiateScenario(pack.fallback, index, pack);
        }
        const raw = templates[variantIdx % templates.length];
        return instantiateScenario({
            ...raw,
            id: combo + '_v' + (variantIdx % templates.length) + '_r' + (index + 1),
            dimension: dimension,
            perspective: perspective,
            role: role
        }, index, pack);
    }

    function selectAdaptiveScenario(gameState, pack) {
        const used = new Set(gameState.responses.map(function (r) { return r.scenarioId; }));
        const candidates = shuffleArray(
            Object.values(pack.adaptive || {})
                .filter(function (s) { return !used.has(s.id); })
                .filter(function (s) { return (s.trigger || function () { return true; })(gameState.profile); })
        );
        if (candidates.length) {
            return instantiateScenario(Object.assign({}, candidates[0], { isAdaptive: true }), gameState.scenarioPtr, pack);
        }
        const fallback = pack.adaptive && pack.adaptive.followup_mixed;
        if (fallback && !used.has(fallback.id)) {
            return instantiateScenario(Object.assign({}, fallback, { isAdaptive: true }), gameState.scenarioPtr, pack);
        }
        return generateTemplateScenario(gameState, gameState.scenarioPtr, pack);
    }

    function getScenarioAt(gameState, index, pack) {
        if (gameState.scenarioCache[index]) {
            return gameState.scenarioCache[index];
        }
        const adaptiveInterval = pack.adaptiveInterval || 9;
        let scenario;
        if (index > 0 && index % adaptiveInterval === 0) {
            scenario = selectAdaptiveScenario(gameState, pack);
        } else {
            scenario = generateTemplateScenario(gameState, index, pack);
        }
        gameState.scenarioCache[index] = scenario;
        return scenario;
    }

    function computeMapPosition(gameState) {
        const p = gameState.profile;
        const max = Math.max(
            Math.abs(p.distributive), Math.abs(p.procedural), Math.abs(p.interactional),
            gameState.responses.length, 1
        );
        const norm = function (v) {
            return Math.round(((v / max) + 1) / 2 * 100);
        };
        return {
            distributive: Math.min(100, Math.max(0, norm(p.distributive))),
            procedural: Math.min(100, Math.max(0, norm(p.procedural))),
            interactional: Math.min(100, Math.max(0, norm(p.interactional)))
        };
    }

    function buildMetaTags(scenario) {
        return '<div class="meta-tags">' +
            '<span class="meta-tag tag-' + scenario.dimension + '">' + DIMENSION_LABELS[scenario.dimension] + '</span>' +
            '<span class="meta-tag tag-' + scenario.perspective + '">' + PERSPECTIVE_LABELS[scenario.perspective] + '</span>' +
            '<span class="meta-tag tag-' + scenario.role + '">' + ROLE_LABELS[scenario.role] + '</span>' +
            '</div>';
    }

    function buildScenarioHTML(scenario, index, total) {
        const progress = Math.round((index / total) * 100);
        return '<div class="game-container">' +
            '<div class="progress-text">第 ' + index + ' / ' + total + ' 轮</div>' +
            '<div class="progress-bar-container"><div class="progress-bar-fill" style="width:' + progress + '%"></div></div>' +
            buildMetaTags(scenario) +
            '<div class="scenario-narrative">' + scenario.narrative + '</div>' +
            '<div class="scenario-question">' + scenario.question + '</div>' +
            '</div>';
    }

    function buildMapHTML(gameState) {
        const pos = computeMapPosition(gameState);
        gameState.systemMapPosition = pos;
        if (!gameState.mapPosition) {
            gameState.mapPosition = Object.assign({}, pos);
        }
        return '<div class="game-container fairness-map-container">' +
            '<div class="game-title">三维公平地图</div>' +
            '<div class="game-subtitle">请确认您在公平空间中的位置</div>' +
            '<p class="map-instruction">三个轴分别代表<strong>分配公平</strong>、<strong>程序公平</strong>、<strong>互动公平</strong>的关注程度。' +
            '系统根据您前 ' + gameState.responses.length + ' 轮的选择估算了位置（蓝色点）。' +
            '请拖动<strong>红色标记</strong>到您认为更符合自己公平观念的位置，确认后提交。</p>' +
            '<div class="map-layout">' +
            '<div class="map-canvas-wrap"><canvas id="fairness-map-canvas" width="520" height="420"></canvas></div>' +
            '<div class="map-sliders">' +
            sliderRow('分配公平', 'dist', pos.distributive) +
            sliderRow('程序公平', 'proc', pos.procedural) +
            sliderRow('互动公平', 'inter', pos.interactional) +
            '</div></div>' +
            '<div class="map-coords" id="map-coords-display"></div>' +
            '<p class="map-hint">可旋转查看三维空间，也可直接使用右侧滑块微调。</p>' +
            '<button type="button" class="jspsych-btn" id="fairness-map-confirm">确认我的公平位置</button>' +
            '</div>';
    }

    function sliderRow(label, key, val) {
        return '<div class="map-slider-row"><label>' + label + '：<span id="val-' + key + '">' + val + '</span></label>' +
            '<input type="range" id="slider-' + key + '" min="0" max="100" value="' + val + '"></div>';
    }

    function initFairnessMap3D(gameState, finishTrial) {
        const canvas = document.getElementById('fairness-map-canvas');
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        const pos = gameState.mapPosition;
        let rotation = 0.55;
        let dragging = false;

        function project(x, y, z) {
            const cx = 260, cy = 210, scale = 1.6;
            const cos = Math.cos(rotation), sin = Math.sin(rotation);
            const xr = x * cos - z * sin;
            const zr = x * sin + z * cos;
            return { px: cx + xr * scale, py: cy - y * scale + zr * 0.35 };
        }

        function draw() {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            ctx.fillStyle = '#f7fafc';
            ctx.fillRect(0, 0, canvas.width, canvas.height);

            const ax = 90;
            const o = project(0, 0, 0);
            const xd = project(ax, 0, 0);
            const yd = project(0, ax, 0);
            const zd = project(0, 0, ax);

            drawAxis(o, xd, '#4299e1', '分配公平');
            drawAxis(o, yd, '#9f7aea', '程序公平');
            drawAxis(o, zd, '#48bb78', '互动公平');

            const sys = gameState.systemMapPosition;
            const sp = project(sys.distributive - 50, sys.procedural - 50, sys.interactional - 50);
            const mp = project(pos.distributive - 50, pos.procedural - 50, pos.interactional - 50);

            drawPoint(sp.px, sp.py, '#4299e1', 9, '系统估计');
            drawPoint(mp.px, mp.py, '#e53e3e', 11, '您的位置');
            updateCoordsDisplay();
        }

        function drawAxis(from, to, color, label) {
            ctx.strokeStyle = color;
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(from.px, from.py);
            ctx.lineTo(to.px, to.py);
            ctx.stroke();
            ctx.fillStyle = color;
            ctx.font = '12px Microsoft YaHei';
            ctx.fillText(label, to.px + 4, to.py - 4);
        }

        function drawPoint(x, y, color, r, label) {
            ctx.beginPath();
            ctx.arc(x, y, r, 0, Math.PI * 2);
            ctx.fillStyle = color;
            ctx.fill();
            ctx.fillStyle = '#2d3748';
            ctx.font = '11px Microsoft YaHei';
            ctx.fillText(label, x + 12, y + 4);
        }

        function updateCoordsDisplay() {
            const el = document.getElementById('map-coords-display');
            if (el) {
                el.textContent = '当前位置 — 分配:' + pos.distributive + '  程序:' + pos.procedural + '  互动:' + pos.interactional;
            }
        }

        function syncSliders() {
            ['dist', 'proc', 'inter'].forEach(function (key, i) {
                const field = ['distributive', 'procedural', 'interactional'][i];
                const slider = document.getElementById('slider-' + key);
                const valEl = document.getElementById('val-' + key);
                if (slider) {
                    slider.value = pos[field];
                    slider.oninput = function () {
                        pos[field] = parseInt(slider.value, 10);
                        if (valEl) valEl.textContent = pos[field];
                        draw();
                    };
                }
            });
        }

        canvas.addEventListener('mousedown', function () { dragging = true; });
        global.addEventListener('mouseup', function () { dragging = false; });
        canvas.addEventListener('mousemove', function (e) {
            if (!dragging) return;
            const rect = canvas.getBoundingClientRect();
            const dx = (e.clientX - rect.left - 260) / 1.6;
            const dy = (210 - (e.clientY - rect.top)) / 1.6;
            pos.distributive = Math.min(100, Math.max(0, Math.round(dx + 50)));
            pos.procedural = Math.min(100, Math.max(0, Math.round(dy + 50)));
            syncSliders();
            draw();
        });
        canvas.addEventListener('wheel', function (e) {
            e.preventDefault();
            rotation += e.deltaY * 0.004;
            draw();
        });

        syncSliders();
        draw();

        const confirmBtn = document.getElementById('fairness-map-confirm');
        if (confirmBtn) {
            confirmBtn.addEventListener('click', function () {
                gameState.mapConfirmed = true;
                gameState.mapPosition = Object.assign({}, pos);
                finishTrial({
                    map_distributive: pos.distributive,
                    map_procedural: pos.procedural,
                    map_interactional: pos.interactional,
                    system_distributive: gameState.systemMapPosition.distributive,
                    system_procedural: gameState.systemMapPosition.procedural,
                    system_interactional: gameState.systemMapPosition.interactional
                });
            });
        }
    }

    function buildProfileSummary(gameState) {
        const pos = gameState.mapPosition || computeMapPosition(gameState);
        const p = gameState.profile;
        const dims = {
            '分配公平': p.distributive,
            '程序公平': p.procedural,
            '互动公平': p.interactional
        };
        const sorted = Object.entries(dims).sort(function (a, b) { return b[1] - a[1]; });
        let dominant = sorted[0][1] > 0 ? sorted[0][0] + '导向' : '综合型';

        let tendency = '温和型';
        if (p.rejectUnfair >= 15) tendency = '原则坚守型';
        else if (p.intervene >= 15) tendency = '积极介入型';
        else if (p.acceptUnfair >= 15) tendency = '务实接受型';
        else if (p.voiceConcern >= 15) tendency = '发声表达型';

        return '<div class="game-container">' +
            '<div class="game-title">测试完成</div>' +
            '<div class="game-subtitle">您的公平观念画像</div>' +
            '<div class="summary-card"><h4>主导公平维度：' + dominant + '</h4><h4>行为倾向：' + tendency + '</h4></div>' +
            '<div class="summary-card"><h4>您确认的三维公平位置</h4>' +
            '<p>分配公平：' + pos.distributive + '　程序公平：' + pos.procedural + '　互动公平：' + pos.interactional + '</p></div>' +
            '<p style="text-align:center;color:#718096;">共完成 ' + gameState.responses.length + ' 轮对话。数据将自动下载。</p>' +
            '<p style="text-align:center;">按任意键结束。</p></div>';
    }

    function downloadCSV(csvContent, filename) {
        const blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = filename;
        link.click();
        URL.revokeObjectURL(link.href);
    }

    function exportData(gameState, pack) {
        const headers = [
            'subjectID', 'scenarioIndex', 'scenarioId', 'dimension', 'perspective', 'role',
            'isAdaptive', 'choiceKey', 'choiceText', 'fairnessRatings', 'textResponse',
            'rt_choice', 'rt_rating', 'rt_text', 'timestamp'
        ];
        let csv = headers.join(',') + '\n';
        gameState.responses.forEach(function (r) {
            csv += headers.map(function (h) {
                let v = r[h];
                if (v === undefined || v === null) v = '';
                if (typeof v === 'object') v = JSON.stringify(v);
                v = String(v).replace(/"/g, '""');
                if (/[,"\n]/.test(v)) v = '"' + v + '"';
                return v;
            }).join(',') + '\n';
        });

        const profileHeaders = [
            'subjectID', 'version', 'totalRounds',
            'distributive', 'procedural', 'interactional',
            'map_distributive', 'map_procedural', 'map_interactional',
            'system_distributive', 'system_procedural', 'system_interactional',
            'acceptUnfair', 'rejectUnfair', 'intervene', 'voiceConcern'
        ];
        let profileCSV = profileHeaders.join(',') + '\n';
        const mp = gameState.mapPosition || {};
        const sp = gameState.systemMapPosition || {};
        profileCSV += [
            gameState.subjectID, pack.id, gameState.config.totalRounds,
            gameState.profile.distributive, gameState.profile.procedural, gameState.profile.interactional,
            mp.distributive || '', mp.procedural || '', mp.interactional || '',
            sp.distributive || '', sp.procedural || '', sp.interactional || '',
            gameState.profile.acceptUnfair, gameState.profile.rejectUnfair,
            gameState.profile.intervene, gameState.profile.voiceConcern
        ].join(',') + '\n';

        const ts = new Date().toISOString().slice(0, 19).replace(/:/g, '-');
        const prefix = pack.exportPrefix || 'FairnessGame';
        downloadCSV(csv, prefix + '_' + gameState.subjectID + '_' + ts + '.csv');
        downloadCSV(profileCSV, prefix + '_Profile_' + gameState.subjectID + '_' + ts + '.csv');
    }

    function shouldCollectText(roundIndex, config) {
        const interval = config.textInterval || 6;
        return (roundIndex + 1) % interval === 0 || roundIndex === config.totalRounds - 1;
    }

    function buildTimeline(gameState, pack, jsPsych) {
        const config = gameState.config;
        const timeline = [];

        timeline.push({
            type: jsPsychHtmlKeyboardResponse,
            stimulus: config.welcomeHTML,
            choices: [' ']
        });

        timeline.push({
            type: jsPsychSurveyText,
            questions: [
                { prompt: '请输入您的被试编号（Subject ID）：', name: 'subjectID', required: true, rows: 1, columns: 30 }
            ],
            data: { trial_type: 'subject_id' },
            on_finish: function (data) {
                gameState.subjectID = (data.response.subjectID || '').trim() || 'unknown';
                jsPsych.data.addProperties({ subjectID: gameState.subjectID, version: pack.id });
            }
        });

        timeline.push({
            type: jsPsychHtmlKeyboardResponse,
            stimulus: config.instructionHTML,
            choices: [' ']
        });

        timeline.push({
            type: jsPsychCallFunction,
            func: function () {
                gameState.scenarioPtr = 0;
                gameState.scenarioCache = {};
                gameState.currentRecord = {};
            }
        });

        const scenarioLoop = {
            timeline: [
                {
                    type: jsPsychHtmlButtonResponse,
                    stimulus: function () {
                        const scenario = getScenarioAt(gameState, gameState.scenarioPtr, pack);
                        return buildScenarioHTML(scenario, gameState.scenarioPtr + 1, config.totalRounds);
                    },
                    choices: function () {
                        return getScenarioAt(gameState, gameState.scenarioPtr, pack).choices.map(function (c) { return c.text; });
                    },
                    button_html: function (choice) {
                        return '<button class="jspsych-btn choice-btn">' + choice + '</button>';
                    },
                    data: function () {
                        const scenario = getScenarioAt(gameState, gameState.scenarioPtr, pack);
                        return {
                            trial_type: 'scenario_choice',
                            scenario_id: scenario.id,
                            round: gameState.scenarioPtr + 1
                        };
                    },
                    on_finish: function (data) {
                        const scenario = getScenarioAt(gameState, gameState.scenarioPtr, pack);
                        const choice = scenario.choices[data.response];
                        gameState.currentRecord = {
                            choiceKey: choice.key,
                            choiceText: choice.text,
                            rt_choice: data.rt,
                            scenario: scenario
                        };
                        updateProfile(gameState, choice.tags);
                    }
                },
                {
                    type: jsPsychSurveyLikert,
                    preamble: '<div class="game-container"><div class="rating-prompt">请对本轮情境的公平程度评分（1=极不公平，5=极公平）</div></div>',
                    questions: function () {
                        const scenario = getScenarioAt(gameState, gameState.scenarioPtr, pack);
                        return scenario.ratings.map(function (label, i) {
                            return {
                                prompt: label,
                                name: 'Q' + i,
                                labels: ['1', '2', '3', '4', '5'],
                                required: true
                            };
                        });
                    },
                    data: { trial_type: 'scenario_rating' },
                    on_finish: function (data) {
                        const scenario = getScenarioAt(gameState, gameState.scenarioPtr, pack);
                        const ratings = {};
                        scenario.ratings.forEach(function (label, i) {
                            ratings[label] = parseInt(data.response['Q' + i], 10) + 1;
                        });
                        gameState.currentRecord.fairnessRatings = ratings;
                        gameState.currentRecord.rt_rating = data.rt;
                    }
                },
                {
                    timeline: [{
                        type: jsPsychSurveyText,
                        questions: [
                            { prompt: '请简要描述：您为何做出上述选择？什么对您而言是"公平"的？', name: 'Q0', rows: 3, columns: 60, required: true }
                        ],
                        data: { trial_type: 'scenario_text' },
                        on_finish: function (data) {
                            gameState.currentRecord.textResponse = data.response.Q0 || Object.values(data.response)[0];
                            gameState.currentRecord.rt_text = data.rt;
                        }
                    }],
                    conditional_function: function () {
                        return shouldCollectText(gameState.scenarioPtr, config);
                    }
                },
                {
                    type: jsPsychCallFunction,
                    func: function () {
                        const rec = gameState.currentRecord;
                        const scenario = rec.scenario;
                        gameState.responses.push({
                            subjectID: gameState.subjectID,
                            scenarioIndex: gameState.scenarioPtr + 1,
                            scenarioId: scenario.id,
                            dimension: scenario.dimension,
                            perspective: scenario.perspective,
                            role: scenario.role,
                            isAdaptive: scenario.isAdaptive,
                            choiceKey: rec.choiceKey,
                            choiceText: rec.choiceText,
                            fairnessRatings: rec.fairnessRatings,
                            textResponse: rec.textResponse || '',
                            rt_choice: rec.rt_choice,
                            rt_rating: rec.rt_rating,
                            rt_text: rec.rt_text || null,
                            timestamp: new Date().toISOString()
                        });
                    }
                }
            ],
            loop_function: function () {
                gameState.scenarioPtr++;
                gameState.currentRecord = {};
                return gameState.scenarioPtr < config.totalRounds;
            }
        };

        timeline.push(scenarioLoop);

        timeline.push({
            type: jsPsychHtmlKeyboardResponse,
            stimulus: function () { return buildMapHTML(gameState); },
            choices: 'NO_KEYS',
            trial_duration: null,
            response_ends_trial: false,
            on_load: function () {
                initFairnessMap3D(gameState, function (mapData) {
                    jsPsych.finishTrial(Object.assign({ trial_type: 'fairness_map' }, mapData));
                });
            },
            data: { trial_type: 'fairness_map' }
        });

        timeline.push({
            type: jsPsychHtmlKeyboardResponse,
            stimulus: function () { return buildProfileSummary(gameState); },
            choices: [' '],
            on_finish: function () { exportData(gameState, pack); },
            data: { trial_type: 'debrief' }
        });

        return timeline;
    }

    function runFairnessGame(config, pack) {
        const params = new URLSearchParams(global.location.search);
        if (params.get('rounds')) {
            config.totalRounds = parseInt(params.get('rounds'), 10) || config.totalRounds;
        }
        const gameState = createGameState(config);
        const jsPsych = initJsPsych({ on_finish: function () {} });
        jsPsych.run(buildTimeline(gameState, pack, jsPsych));
    }

    global.FairnessGameCore = {
        run: runFairnessGame,
        DIMENSION_LABELS: DIMENSION_LABELS,
        PERSPECTIVE_LABELS: PERSPECTIVE_LABELS,
        ROLE_LABELS: ROLE_LABELS,
        templateKey: templateKey
    };
})(window);
