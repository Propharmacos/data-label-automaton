import { getApiConfig } from "@/config/api";
import { FilaImpressaoItem, ImpressoraConfig } from "@/types/requisicao";
import { ApiResponse } from "@/services/requisicaoService";

const getHeaders = () => ({
  "Content-Type": "application/json",
  "ngrok-skip-browser-warning": "true",
});

export const buscarFilaImpressao = async (filial?: string): Promise<ApiResponse<FilaImpressaoItem[]>> => {
  const config = getApiConfig();
  const fil = filial || config.codigoFilial;

  try {
    const response = await fetch(
      `${config.serverUrl}/api/fila-impressao?filial=${fil}`,
      { method: "GET", headers: getHeaders() }
    );

    if (!response.ok) throw new Error(`Erro HTTP: ${response.status}`);

    const result = await response.json();
    if (!result.success) throw new Error(result.error || "Erro ao buscar fila");

    const items: FilaImpressaoItem[] = (result.data || []).map((item: any) => ({
      nrRequisicao: item.nrRequisicao || item.NRRQU || "",
      serieRotulo: item.serieRotulo || item.SERIER || "",
      status: item.status ?? item.STATUS ?? 0,
      codigoRotulo: item.codigoRotulo || item.CODIGOROTULO || "",
      dataCriacao: item.dataCriacao || item.DTCRIACAO || "",
      nomePC: item.nomePC || item.NOMEPC || "",
    }));

    return { success: true, data: items };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : "Erro ao buscar fila de impressão",
    };
  }
};

export const marcarParaImpressao = async (
  ids: Array<{ nrRequisicao: string; serieRotulo: string }>
): Promise<ApiResponse<{ atualizados: number }>> => {
  const config = getApiConfig();

  try {
    const response = await fetch(`${config.serverUrl}/api/fila-impressao/marcar`, {
      method: "POST",
      headers: getHeaders(),
      body: JSON.stringify({ ids }),
    });

    if (!response.ok) throw new Error(`Erro HTTP: ${response.status}`);

    const result = await response.json();
    if (!result.success) throw new Error(result.error || "Erro ao marcar para impressão");

    return { success: true, data: result.data };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : "Erro ao marcar para impressão",
    };
  }
};

export const buscarConfigImpressoras = async (): Promise<ApiResponse<ImpressoraConfig[]>> => {
  const config = getApiConfig();

  try {
    const response = await fetch(`${config.serverUrl}/api/impressoras-config`, {
      method: "GET",
      headers: getHeaders(),
    });

    if (!response.ok) throw new Error(`Erro HTTP: ${response.status}`);

    const result = await response.json();
    if (!result.success) throw new Error(result.error || "Erro ao buscar impressoras");

    const items: ImpressoraConfig[] = (result.data || []).map((item: any) => ({
      rotuloId: item.rotuloId || item.ROTULOID || "",
      altura: item.altura || item.ALTURA || 0,
      largura: item.largura || item.LARGURA || 0,
      tipoImpressora: item.tipoImpressora || item.TPIMPRESSORA || "",
      portaRede: item.portaRede || item.PORTAREDE || "",
      nomePC: item.nomePC || item.NOMEPC || "",
    }));

    return { success: true, data: items };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : "Erro ao buscar configurações de impressoras",
    };
  }
};
