import { useState, useRef, useEffect, useCallback, forwardRef } from "react";
import { Button } from "@/components/ui/button";
import { Slider } from "@/components/ui/slider";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Save, RotateCcw, Move, Eye, EyeOff, GripVertical } from "lucide-react";
import { LayoutConfig, LabelFieldId, FieldPosition, RotuloItem, PharmacyConfig, LabelConfig } from "@/types/requisicao";
import { fieldLabels, saveLayout, resetLayout } from "@/config/layouts";
import { useToast } from "@/hooks/use-toast";
import PharmacyHeader from "./PharmacyHeader";

// Constantes para dimensões (igual ao LabelCard)
const FIELD_AREA_HEIGHT = 140; // px - altura base da área de campos
const PREVIEW_SCALE = 1.8; // Escala visual para facilitar edição

interface LayoutEditorProps {
  layout: LayoutConfig;
  onSave: (layout: LayoutConfig) => void;
  onClose?: () => void;
  previewData?: RotuloItem;
  pharmacyConfig?: PharmacyConfig;
  labelConfig?: LabelConfig;
}

const LayoutEditor = forwardRef<HTMLDivElement, LayoutEditorProps>(({ 
  layout, 
  onSave, 
  onClose, 
  previewData,
  pharmacyConfig,
  labelConfig 
}, ref) => {
  const { toast } = useToast();
  const [editedLayout, setEditedLayout] = useState<LayoutConfig>(() => 
    JSON.parse(JSON.stringify(layout))
  );
  const [selectedField, setSelectedField] = useState<LabelFieldId | null>(null);
  const [dragging, setDragging] = useState<LabelFieldId | null>(null);
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });
  const previewRef = useRef<HTMLDivElement>(null);

  // Calcular largura do rótulo baseado no labelConfig
  const mmToPx = (mm: number) => Math.round(mm * 3.78);
  const labelWidth = labelConfig ? mmToPx(labelConfig.larguraMM) : 300;

  // Reset quando layout mudar
  useEffect(() => {
    setEditedLayout(JSON.parse(JSON.stringify(layout)));
  }, [layout]);

  // Dados para preview - usa dados reais quando disponíveis
  const getDisplayData = (): Record<LabelFieldId, string> => {
    if (previewData) {
      // Formatar data curta (MM/AA)
      const formatarDataCurta = (data: string) => {
        if (!data) return "";
        const partes = data.split('/');
        if (partes.length === 3) {
          return `${partes[1]}/${partes[2].slice(-2)}`;
        }
        return data;
      };

      // Formatar lote como lote/ano
      const formatarLote = () => {
        const lote = previewData.lote || "";
        if (lote.includes('/')) return lote;
        const ano = formatarDataCurta(previewData.dataFabricacao).split('/')[1] || "";
        return lote ? `${lote}/${ano}` : "";
      };

      // Remover prefixo "AMP " do nome da fórmula
      const formatarFormula = (formula: string) => {
        if (!formula) return "";
        let nome = formula;
        if (nome.toUpperCase().startsWith("AMP ")) {
          nome = nome.substring(4);
        }
        return nome.toUpperCase();
      };

      return {
        medico: previewData.numeroCRM 
          ? `${(previewData.prefixoCRM || 'DR').toUpperCase()} ${previewData.nomeMedico?.toUpperCase() || ''} - CRM ${previewData.numeroCRM}/${previewData.ufCRM}`
          : '',
        paciente: previewData.nomePaciente || '',
        requisicao: `REQ:${previewData.nrRequisicao || ''}-${previewData.nrItem || ''}`,
        formula: formatarFormula(previewData.formula || previewData.descricaoProduto || ''),
        lote: `L:${formatarLote() || '___'}`,
        fabricacao: `F:${formatarDataCurta(previewData.dataFabricacao)}`,
        validade: `V:${formatarDataCurta(previewData.dataValidade)}`,
        ph: previewData.ph ? `pH:${previewData.ph}` : 'pH:___',
        aplicacao: `APLIC:${previewData.aplicacao?.toUpperCase() || '___'}`,
        tipoUso: previewData.tipoUso?.toUpperCase() || 'USO',
        contem: `CONT:${previewData.contem?.toUpperCase() || '___'}`,
        posologia: previewData.posologia ? `Pos: ${previewData.posologia}` : '',
        observacoes: previewData.observacoes ? `Obs: ${previewData.observacoes}` : '',
        registro: previewData.numeroRegistro ? `REG:${previewData.numeroRegistro}` : '',
      };
    }
    
    // Fallback para dados de exemplo
    return {
      medico: 'DR EXEMPLO - CRM 0000/XX',
      paciente: 'PACIENTE EXEMPLO',
      requisicao: 'REQ:000000-0',
      formula: 'FORMULA EXEMPLO',
      lote: 'L:000/00',
      fabricacao: 'F:00/00',
      validade: 'V:00/00',
      ph: 'pH:0.0',
      aplicacao: 'APLIC:IM/EV/SC',
      tipoUso: 'USO EXEMPLO',
      contem: 'CONT:EXEMPLO',
      posologia: 'Pos: Conforme prescrição',
      observacoes: 'Obs: Exemplo',
      registro: 'REG:00000',
    };
  };

  const displayData = getDisplayData();

  const handleFieldUpdate = useCallback((fieldId: LabelFieldId, updates: Partial<FieldPosition>) => {
    setEditedLayout(prev => ({
      ...prev,
      campos: {
        ...prev.campos,
        [fieldId]: {
          ...prev.campos[fieldId],
          ...updates,
        },
      },
    }));
  }, []);

  const handleMouseDown = (e: React.MouseEvent, fieldId: LabelFieldId) => {
    e.preventDefault();
    e.stopPropagation();
    
    if (!previewRef.current) return;
    
    const rect = previewRef.current.getBoundingClientRect();
    const field = editedLayout.campos[fieldId];
    
    // Calcular posição atual do campo considerando a escala
    const fieldX = (field.x / 100) * (labelWidth * PREVIEW_SCALE);
    const fieldY = (field.y / 100) * (FIELD_AREA_HEIGHT * PREVIEW_SCALE);
    
    setDragOffset({
      x: e.clientX - rect.left - fieldX,
      y: e.clientY - rect.top - fieldY
    });
    
    setDragging(fieldId);
    setSelectedField(fieldId);
  };

  const handleMouseMove = useCallback((e: MouseEvent) => {
    if (!dragging || !previewRef.current) return;

    const rect = previewRef.current.getBoundingClientRect();
    
    // Usar dimensões escaladas para cálculos
    const scaledWidth = labelWidth * PREVIEW_SCALE;
    const scaledHeight = FIELD_AREA_HEIGHT * PREVIEW_SCALE;
    
    const x = ((e.clientX - rect.left - dragOffset.x) / scaledWidth) * 100;
    const y = ((e.clientY - rect.top - dragOffset.y) / scaledHeight) * 100;

    // Limitar dentro do preview
    const clampedX = Math.max(0, Math.min(95, x));
    const clampedY = Math.max(0, Math.min(90, y));

    handleFieldUpdate(dragging, { x: clampedX, y: clampedY });
  }, [dragging, dragOffset, handleFieldUpdate, labelWidth]);

  const handleMouseUp = useCallback(() => {
    setDragging(null);
  }, []);

  useEffect(() => {
    if (dragging) {
      document.addEventListener('mousemove', handleMouseMove);
      document.addEventListener('mouseup', handleMouseUp);
      return () => {
        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', handleMouseUp);
      };
    }
  }, [dragging, handleMouseMove, handleMouseUp]);

  const handleSave = () => {
    saveLayout(editedLayout);
    onSave(editedLayout);
    toast({
      title: "Layout salvo!",
      description: `O layout ${editedLayout.nome} foi salvo com sucesso.`,
    });
  };

  const handleReset = () => {
    const resetted = resetLayout(layout.tipo);
    setEditedLayout(JSON.parse(JSON.stringify(resetted)));
    toast({
      title: "Layout resetado",
      description: "O layout foi restaurado para o padrão.",
    });
  };

  const allFields = Object.keys(editedLayout.campos) as LabelFieldId[];

  // Configuração padrão da farmácia para preview
  const defaultPharmacyConfig: PharmacyConfig = pharmacyConfig || {
    nome: "FARMÁCIA EXEMPLO",
    telefone: "(00) 0000-0000",
    endereco: "Endereço Exemplo",
    cnpj: "00.000.000/0000-00",
    farmaceutico: "Farm. Exemplo",
    crf: "CRF-XX 0000"
  };

  return (
    <div className="space-y-4">
      <div className="flex justify-end gap-2 mb-2">
        <Button variant="outline" size="sm" onClick={handleReset}>
          <RotateCcw className="h-4 w-4 mr-1" />
          Resetar
        </Button>
        <Button size="sm" onClick={handleSave}>
          <Save className="h-4 w-4 mr-1" />
          Salvar
        </Button>
      </div>

      <div className="grid md:grid-cols-2 gap-6">
        {/* Preview do rótulo - espelha LabelCard */}
        <div>
          <p className="text-sm text-muted-foreground mb-2 flex items-center gap-1">
            <Move className="h-3 w-3" />
            Arraste os campos para reposicioná-los
          </p>
          
          {/* Container com escala visual */}
          <div 
            className="bg-white border-2 border-dashed border-primary/50 rounded-lg overflow-hidden"
            style={{ 
              width: `${labelWidth * PREVIEW_SCALE}px`,
              padding: `${12 * PREVIEW_SCALE}px`,
            }}
          >
            {/* Cabeçalho da Farmácia - igual ao LabelCard */}
            <div style={{ transform: `scale(${PREVIEW_SCALE})`, transformOrigin: 'top left', width: `${100/PREVIEW_SCALE}%` }}>
              <PharmacyHeader config={defaultPharmacyConfig} compact />
            </div>
            
            {/* Área de campos posicionáveis */}
            <div
              ref={previewRef}
              className="relative select-none font-mono"
              style={{ 
                height: `${FIELD_AREA_HEIGHT * PREVIEW_SCALE}px`,
                marginTop: `${8 * PREVIEW_SCALE}px`
              }}
            >
              {/* Grid de fundo para ajudar no posicionamento */}
              <div 
                className="absolute inset-0 pointer-events-none opacity-20"
                style={{
                  backgroundImage: 'linear-gradient(to right, #ccc 1px, transparent 1px), linear-gradient(to bottom, #ccc 1px, transparent 1px)',
                  backgroundSize: '10% 10%'
                }}
              />
              
              {allFields.map((fieldId) => {
                const field = editedLayout.campos[fieldId];
                if (!field.visible) return null;

                const isSelected = selectedField === fieldId;
                const isDragging = dragging === fieldId;

                return (
                  <div
                    key={fieldId}
                    className={`absolute cursor-grab active:cursor-grabbing flex items-center gap-1 px-1 py-0.5 rounded transition-colors select-none ${
                      isSelected
                        ? 'ring-2 ring-primary bg-primary/20 z-20'
                        : 'hover:bg-primary/10 z-10'
                    } ${isDragging ? 'opacity-80 shadow-lg z-30' : ''}`}
                    style={{
                      left: `${field.x}%`,
                      top: `${field.y}%`,
                      maxWidth: `${field.width}%`,
                      fontSize: `${field.fontSize * PREVIEW_SCALE}px`,
                    }}
                    onMouseDown={(e) => handleMouseDown(e, fieldId)}
                  >
                    <GripVertical className="h-3 w-3 text-muted-foreground flex-shrink-0" style={{ transform: `scale(${PREVIEW_SCALE * 0.8})` }} />
                    <span className="text-foreground whitespace-nowrap overflow-hidden text-ellipsis">
                      {displayData[fieldId]}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
          
          <p className="text-xs text-muted-foreground mt-2">
            Escala: {PREVIEW_SCALE}x • Tamanho real: {labelWidth}px × {FIELD_AREA_HEIGHT}px
          </p>
        </div>

        {/* Painel de propriedades */}
        <div className="space-y-4">
          <p className="text-sm font-medium">Campos do Rótulo</p>
          <div className="max-h-[400px] overflow-y-auto space-y-2 pr-2">
            {allFields.map((fieldId) => {
              const field = editedLayout.campos[fieldId];
              const isSelected = selectedField === fieldId;

              return (
                <div
                  key={fieldId}
                  className={`p-2 rounded border cursor-pointer transition-all ${
                    isSelected
                      ? 'border-primary bg-primary/5'
                      : 'border-border hover:border-primary/50'
                  }`}
                  onClick={() => setSelectedField(fieldId)}
                >
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-sm font-medium">{fieldLabels[fieldId]}</span>
                    <div className="flex items-center gap-2">
                      {field.visible ? (
                        <Eye className="h-3 w-3 text-green-600" />
                      ) : (
                        <EyeOff className="h-3 w-3 text-muted-foreground" />
                      )}
                      <Switch
                        checked={field.visible}
                        onCheckedChange={(checked) =>
                          handleFieldUpdate(fieldId, { visible: checked })
                        }
                      />
                    </div>
                  </div>

                  {isSelected && field.visible && (
                    <div className="space-y-3 mt-3 pt-3 border-t">
                      <div className="space-y-1">
                        <Label className="text-xs">Tamanho da fonte: {field.fontSize}px</Label>
                        <Slider
                          value={[field.fontSize]}
                          min={6}
                          max={18}
                          step={1}
                          onValueChange={([v]) => handleFieldUpdate(fieldId, { fontSize: v })}
                        />
                      </div>
                      <div className="space-y-1">
                        <Label className="text-xs">Largura máxima: {field.width.toFixed(0)}%</Label>
                        <Slider
                          value={[field.width]}
                          min={10}
                          max={100}
                          step={5}
                          onValueChange={([v]) => handleFieldUpdate(fieldId, { width: v })}
                        />
                      </div>
                      <div className="grid grid-cols-2 gap-2">
                        <div className="space-y-1">
                          <Label className="text-xs">Posição X: {field.x.toFixed(0)}%</Label>
                          <Slider
                            value={[field.x]}
                            min={0}
                            max={90}
                            step={1}
                            onValueChange={([v]) => handleFieldUpdate(fieldId, { x: v })}
                          />
                        </div>
                        <div className="space-y-1">
                          <Label className="text-xs">Posição Y: {field.y.toFixed(0)}%</Label>
                          <Slider
                            value={[field.y]}
                            min={0}
                            max={90}
                            step={1}
                            onValueChange={([v]) => handleFieldUpdate(fieldId, { y: v })}
                          />
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
});

LayoutEditor.displayName = "LayoutEditor";

export default LayoutEditor;
